-- Copyright (C) idevz (idevz.org)


local cjson = require('cjson')
local json_decode = cjson.decode
local json_encode = cjson.encode
local ngx = ngx
local resty_lock = require "resty.lock"
local http = require "resty.vintage.http"
local timer = require "resty.timer"
local ngx_re_find = ngx.re.find

local status = {
	STATUS_OK                  = "200",
	STATUS_BADREQUEST          = "400",
	STATUS_UNAUTHORIZED        = "401",
	STATUS_INTERNALSERVERERROR = "500",
	STATUS_SERVICEUNAVAILABLE  = "503",
	STATUS_NOTMODIFIED         = "304"
}

local STATICS = "statics"
local DYNAMIC = "dynamic"

local apis = {
	----------------------------- name_service -----------------------------
	PATH_NAMING_SERVICE                     = "/naming/service",
	PATH_NAMING_SERVICE_LOOKUP              = "/naming/service?action=lookup&service=%s&cluster=%s",
	PATH_NAMING_SERVICE_LOOKUP_FOR_UPDATE   = "/naming/service?action=lookupforupdate&service=%s&cluster=%s&sign=%s",
	PATH_NAMING_SERVICE_REGISTER            = "action=register&service=%s&cluster=%s&node=%s&_i=%s",
	PATH_NAMING_SERVICE_UNREGISTER          = "action=unregister&service=%s&cluster=%s&node=%s",
	PATH_NAMING_SERVICE_BATCH_UNREGISTER    = "action=batchunregister&service=%s&node=%s",
	PATH_NAMING_SERVICE_GET_NODE_SERVICE    = "/naming/service?action=getnodeservice&ip=%s",
	PATH_NAMING_SERVICE_GET_NODE_INFO       = "/naming/service?action=getnodeinfo&ip=%s&service=%s",
	PATH_NAMING_SERVICE_GET_SIGN            = "/naming/service?action=getsign&service=%s&cluster=%s",
	PATH_NAMING_SERVICE_UPDATE_SIGN         = "/naming/service?action=updatesign&service=%s&cluster=%s",

	----------------------------- heart_beat -----------------------------
	PATH_NAMING_SERVICE_HEARTBEAT           = "action=heartbeat&message=%s",

	----------------------------- naming_admin -----------------------------
	PATH_NAMING_ADMIN                       = "/naming/admin",
	PATH_NAMING_ADMIN_GET_SERVICE           = "/naming/admin?action=getservice",
	PATH_NAMING_ADMIN_GET_SERVICE_WITH_NAME = "/naming/admin?action=getservice&service=%s",
	PATH_NAMING_ADMIN_ADD_DYNAMIC           = "action=addservice&service=%s&type=dynamic",
	PATH_NAMING_ADMIN_ADD_DYNAMIC_THRESHOLD = "action=addservice&service=%s&type=dynamic&threshold=%f",
	PATH_NAMING_ADMIN_ADD_STATICS           = "action=addservice&service=%s&type=statics",
	PATH_NAMING_ADMIN_UPDATE_TYPE           = "action=updateservice&service=%s&type=%s",
	PATH_NAMING_ADMIN_UPDATE_THRESHOLD      = "action=updateservice&service=%s&threshold=%f",
	PATH_NAMING_ADMIN_DeleteSERVICE         = "/naming/admin?action=deleteservice&service=%s",
	PATH_NAMING_ADMIN_GET_CLUSTER           = "/naming/admin?action=getcluster&service=%s",
	PATH_NAMING_ADMIN_ADD_CLUSTER           = "action=addcluster&service=%s&cluster=%s",
	PATH_NAMING_ADMIN_DELETE_CLUSTER        = "action=deletecluster&service=%s&cluster=%s",
}

local NAMING_SERVICE_LOOKUP_KEY = "naming_service_lookup"
local NAMING_SERVICE_WATCH_KEY  = "naming_service_watch"

local safe_json_decode
safe_json_decode = function(json_str)
    local ok, json_or_err = pcall(json_decode, json_str)
    if ok then
        return json_or_err
    else
		ngx.log(ngx.ERR, json)
		return nil, json_or_err
    end
end

local get_timer_key
get_timer_key = function(func_tag, service_name, cluster_name)
	local func_tag = func_tag or ""
	local service_name = service_name or ""
	local cluster_name = cluster_name or ""
	local key_arr = {func_tag, "/", service_name, "/", cluster_name}
	return table.concat(key_arr, "")
end

-- / ----------------------------- X ----------------------------- api_client ----------------------------- X ---------------------------- / --
local name_response = {
	code = "",
	body = "",
	__call = function(self, code, body)
		self.code = code or status.STATUS_OK
		self.body = body or ""
		return self
	end,
	is_success = function(self)
		return self.code == status.STATUS_OK
	end,
	get_body = function(self)
		return self.body
	end
}
setmetatable(name_response, name_response)

local vintage_err = {
	err_code = "",
	err_msg = "",
	request = "",
	__call = function(self, err_code, err_msg, request)
		self.err_code = err_code or ""
		self.err_msg = err_msg  or ""
		self.request = request  or ""
		return self
	end,
	error = function(self)
		return string.format( "error_code: %s, error: %s, request: %s", self.err_code, self.err_msg, self.request)
	end
}
setmetatable(vintage_err, vintage_err)

local parse_vintage_err
parse_vintage_err = function(err_resp)
	if err_resp:is_success() then
		return nil, nil
	end
	local res, err = safe_json_decode(err_resp.body)
	if not res then
		return nil, err
	end
	return vintage_err(res.error_Code, res.error, res.request)
end

local yield_able
yield_able = function()
	local phase = ngx.get_phase()
	local not_yield_able_phases = "init,init_worker,header_filter,body_filter,balancer,log"
	local from, to, err = ngx_re_find(not_yield_able_phases, phase, "jo")
	if from == nil then
		return true
	else
		return false
	end
end

local config_response
config_response = function(code, body)
	return name_response(name_response, code, body)
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M:new(opts)
	local addr = opts.addr
	assert(addr ~= nil, "Vintage addr must not be nil.")

	local shm = opts.shm
	assert(shm ~= nil, "Vintage need a share dict to store nodes.")

	local watch_timers = timer:new(true, shm)

	local timeout = opts.timeout
	local http_client = http:new{
		connect_timeout  = timeout,
		send_timeout     = timeout,
		read_timeout     = timeout
	}

	local heart_interval = opts.heart_interval or 5
	
	local phase = ngx.get_phase()
	assert(phase == "init_worker", "This lib should using in init_worker phase.")

    local client_t = {
		addr = addr,
		shm = shm,
		watch_timers = watch_timers,
		http_client = http_client,
		started = false,
		stopped = false,
		-- stopChan   chan bool
		heart_interval = heart_interval,
		heartbeat_map = {},
		-- nsWatchMap  map[string](map[string][]*NamingSericeWatchChan)
		heartbeat_lock = nil,
		-- heartbeatLock sync.RWMutex

		ns_watch_map = {},
		-- nsWatchMap  map[string](map[string][]*NamingSericeWatchChan)
		ns_watch_lock = nil,
		-- nsWatchLock sync.Mutex

		config_watch_group = {},
		config_watch_lock = nil,
		-- configWatchLock  sync.Mutex

		config_key_md5 = {},
		config_key_watch_map = {},
		-- configKeyWatchMap  map[string][]*ConfigKeyWatchChan
		config_key_watch_lock = nil,
		-- configKeyWatchLock sync.Mutex

		config_value_watch_map = {},
		-- configValueWatchMap  map[string][]*ConfigValueWatchChan
		config_value_watch_lock = nil,
		-- configValueWatchLock sync.Mutex

		-- //switches
		-- // Enable_heartbeat 控制心跳开关，默认true. 如果设置为false,则不会向vintage服务器发送heartbeat。
		enable_heartbeat = false,
		-- // EnableSnapshot 是否支持snapshot, 默认为true.
		enable_snapshot = false,
		-- EnableSnapshot bool

		-- //cache
		lookuped_clusters = {},
		lookuped_clusters_lock = lookuped_clusters_lock,
		-- lookuped_csLock  sync.Mutex
		lookuped_group_keys = {},
		lookuped_group_keys_lock = nil,
		-- lookupedGroupKeysLock sync.Mutex

		-- //snapshot
		-- // SnapshotInterval 是定时创建快照的间隔, 默认是10秒.
		snapshot_interval = 10,
		-- // SnapshotDir 是快照存放的文件夹，默认是当前文件夹.
		snapshot_dir = opts.snapshot_dir or "",

		-- // ExciseStrategy 节点摘除策略,默认全部保留(100). 用户可以使用RatioExciseStrategy定义摘除一定比率的节点.
		node_excise_strategy = nil
	}
    return setmetatable(client_t, mt)
end

function _M:start()
	if not self.started then
		self:start_heartbeat()
		self.started = true
	end
	return nil
end

function _M:stop()
end

function _M:get_naming(context_path)
	local resp, err = self.http_client:get(self.addr .. context_path)
	if not resp then
		return nil, err
	end
	local rs, err = safe_json_decode(resp.body)
	if not rs then
		return nil, err
	end
	return name_response(rs.code, rs.body)
end

function _M:get_config(context_path)
	return self.http_client:get(self.addr .. context_path)
end

function _M:post_naming(context_path, data)
	local resp, err = self.http_client:post(self.addr .. context_path, data)
	if err ~= nil then
		return nil, err
	end
	local rs, err = safe_json_decode(resp)
	if not rs then
		return nil, err
	end
	return name_response(rs.code, rs.body)
end

function _M:post_config(context_path, data)
end

-- / ----------------------------- X ----------------------------- name_service ----------------------------- X ---------------------------- / --

local batch_unregister_result_t = {
	results = {
		{
			cluster = "",
			result = false
		}
	},
	service = ""
}

local service_list_t = {
	service = {}
}

local node_info_result_t = {
	node_info = {},
	service = ""
}

local node_info_t = {
	cluster = "",
	host = {}
}

function _M:naming_service_lookup(service_name, cluster_name)
	local service_name = service_name or nil
	local cluster_name = cluster_name or nil
	if service_name == nil or cluster_name == nil then
		return nil, "Err Empty Parameter"
	end
	local sc_key = service_name .. "/" .. cluster_name
	local sn, err = self:get_cluster_cache(service_name, cluster_name)
	if err ~= nil then
		return nil, err
	end

	local watch_timer_key = get_timer_key(
		NAMING_SERVICE_LOOKUP_KEY, service_name, cluster_name)
	if not self.lookuped_clusters[sc_key] then
		self.watch_timers:tick(
			watch_timer_key, self.heart_interval, 
			self.remote_naming_service_lookup, 
			self, service_name, cluster_name)
		self.lookuped_clusters[sc_key] = true
	end
	return sn, err
end

function _M:get_res(service_name, cluster_name)
	local watch_timer_key = get_timer_key(
		NAMING_SERVICE_LOOKUP_KEY, service_name, cluster_name)
	return self.watch_timers:get_res(watch_timer_key)
end

function _M:remote_naming_service_lookup(service_name, cluster_name)
	local resp, err = self:get_naming(
		string.format(apis.PATH_NAMING_SERVICE_LOOKUP, 
		service_name, cluster_name))
	if not resp then
		return nil, err
	end
	if not resp:is_success() then
		local ne, err = parse_vintage_err(resp)
		if not ne then
			return nil, err
		end
		return nil, ne
	end
	local sn, err = safe_json_decode(resp.body)
	if not sn then
		return nil, err
	end
	return sn
end

function _M:naming_service_lookup_for_update(service_name, cluster_name, sign)
	local service_name, cluster_name
		= service_name or ""
		, cluster_name or ""
	if service_name == ""
	or cluster_name == "" then
		return nil, "naming_service_lookup_for_update Err: empty parameter."
	end
	local http_resp, err = self.http_client:get(self.addr
	.. string.format(apis.PATH_NAMING_SERVICE_LOOKUP_FOR_UPDATE
	, service_name, cluster_name, sign))
	if err ~= nil then
		return false, nil, err
	end
	if http_resp.status == 304 then
		return true, nil, http_resp.reason
	end
	local rs, err = safe_json_decode(http_resp.body)
	if not rs then
		return false, nil, err
	end
	local ns_resp = name_response(rs.code, rs.body)
	if not ns_resp:is_success() then
		local ne, err = parse_vintage_err(ns_resp)
		if err ~= nil then
			return false, nil, err
		end
		return false, nil, ne
	end
	local sn = safe_json_decode(ns_resp.body)
	return false, sn, err
end

function _M:register_node(service_name, cluster_name, node, ext_info)
	local service_name, cluster_name, node, ext_info
		= service_name or ""
		, cluster_name or ""
		, node or ""
	if service_name == ""
	or cluster_name == "" 
	or node == "" then
		return nil, "register_node Err: empty parameter."
	end
	local ext_info = ngx.escape_uri(ext_info)
	local ok, err = self:post_common_bool_resp(apis.PATH_NAMING_SERVICE
	, apis.PATH_NAMING_SERVICE_REGISTER
	, service_name, cluster_name, node, ext_info)
	if err ~= nil then
		ngx.log(ngx.ERR, err.err_msg)
		return nil, err
	end
	return ok, err
end

function _M:unregister_node(service_name, cluster_name, node)
	local service_name, cluster_name, node
		= service_name or ""
		, cluster_name or ""
		, node or ""
	if service_name == ""
	or cluster_name == "" 
	or node == "" then
		return nil, "unregister_node Err: empty parameter."
	end
	local ok, err = self:post_common_bool_resp(apis.PATH_NAMING_SERVICE
	, apis.PATH_NAMING_SERVICE_UNREGISTER
	, service_name, cluster_name, node)
	if ok then
		self:unheartbeat(service_name, cluster_name, node)
	end
	return ok, err
end

function _M:unregisterAll_nodes()
	local heartbeat_map = self.heartbeat_map
	local unregister_failed = {}
	for service_name, v in pairs(heartbeat_map) do
		for cluster_name, nodes in pairs(v) do
			for _, node in ipairs(nodes) do
				local ok = self:post_common_bool_resp(apis.PATH_NAMING_SERVICE
						   , apis.PATH_NAMING_SERVICE_UNREGISTER
						   , service_name, cluster_name, node)
				if not ok then
					table.insert(unregister_failed, 
					table.concat({service_name, cluster_name, node}, ","))
				end
			end
		end
	end
	return unregister_failed
end

function _M:batch_unregister_node(service_name, node)
end

function _M:get_node_service(nodeIP)
end

function _M:get_node_info(service_name, nodeIP)
end

function _M:naming_service_get_sign(service_name, cluster_name)
end

function _M:naming_service_update_sign(service_name, cluster_name)
end

-- / ----------------------------- X ----------------------------- cache ----------------------------- X ---------------------------- / --

function _M:set_cluster_cache(cluster_key, service_node)
end

function _M:get_cluster_cache(service_name, cluster_name)
end

function _M:set_key_cache(group_name, config_node, sign)
end

function _M:get_key_cache(group_name)
end


-- / ----------------------------- X ----------------------------- heart_beat ----------------------------- X ---------------------------- / --
local HEART_RETRY  = 3
local COMMON_RETRY = 3
local cluster_node_t = {
	cluster = "",
	node = ""
}

local service_cluster_t = {
	clusters = {
		cluster_node_t,
	},
	service = ""
}

local heartbeat_req_t = {
	heart_beat = {service_cluster_t}
}

function _M:start_heartbeat()
	local heart_beat_timer = timer:new(true)
	heart_beat_timer:tick(
		heart_beat_timer.NO_RES, self.heart_interval, 
		self.do_heartbeat, 
		self)
end

function _M:do_heartbeat()
	-- if not self.enable_heartbeat then
	-- 	return
	-- end
	local req = json_encode(self:map2_heartbeat_request())
	local ok, retry, err = false, HEART_RETRY
	for i = retry, 0, -1 do
		ok, err = self:post_common_bool_resp(apis.PATH_NAMING_SERVICE
		, apis.PATH_NAMING_SERVICE_HEARTBEAT, req)
		if ok then
			return
		end
	end
	return ok, err
end

function _M:map2_heartbeat_request()
	local req = {heartBeat={}}
	for service_id, cluster_and_nodes in pairs(self.heartbeat_map) do
		local sc, nodes = {service = service_id}, {}
		for c, ns in pairs(cluster_and_nodes) do
			for _, n in ipairs(ns) do
				table.insert(nodes, {
					cluster = c,
					node = n
				})
			end
		end
		sc.clusters = nodes
		table.insert(req.heartBeat, sc)
	end
	return req
end

function _M:heartbeat(service_name, cluster_name, node)
	local service_name, cluster_name, node 
		= service_name or ""
		, cluster_name or ""
		, node or ""
	if service_name == ""
	or cluster_name == "" 
	or node == "" then
		return nil, "heartbeat Err: empty parameter."
	end
	local services, err = self:get_service(service_name)
	if err ~= nil then
		return nil, err
	end
	if services ~= nil 
	and #services.services == 1
	and services.services[1].type == DYNAMIC then
		local m = self.heartbeat_map[service_name]
		if m == nil then
			m = {}
		end
		self.heartbeat_map[service_name] = m
		local nodes = m[cluster_name]
		if nodes == nil then
			nodes = {}
		end
		for _, n in ipairs(nodes) do
			if n == node then
				return nil
			end
		end
		table.insert(nodes, node)
		m[cluster_name] = nodes
	end
end

function _M:unheartbeat(service_name, cluster_name, node)
end


-- / ----------------------------- X ----------------------------- naming_admin ----------------------------- X ---------------------------- / --
function _M:get_service(service_name)
	local ctx_path = ""
	if service_name == "" then
		ctx_path = ctx_path .. apis.PATH_NAMING_ADMIN_GET_SERVICE
	else
		ctx_path = ctx_path .. string.format(apis.PATH_NAMING_ADMIN_GET_SERVICE_WITH_NAME, service_name)
	end

	local resp, err = self:get_naming(ctx_path)
	if err ~= nil then
		return nil, err
	end
	if not resp:is_success() then
		local ne, err = parse_vintage_err(resp)
		if err ~= nil then
			return nil, err
		end
		return nil, ne
	end
	local services, err = safe_json_decode(resp.body)
	return services, err
end

function _M:get_cluster(service_name)
end

function _M:add_static_service(service_name)
end

function _M:add_dynamic_service(service_name)
end

function _M:add_dynamic_service_and_threshold(service_name, threshold)
end

function _M:delete_service(service_name)
end

function _M:update_service_type(service_name, service_type)
end

function _M:update_service_threshold(service_name, t)
end

function _M:add_cluster(service_name, cluster_name)
end

function _M:delete_cluster(service_name, cluster_name)
end

function _M:post_common_bool_resp(ctx_path, fmtstr, ...)
	local ctx_path = ctx_path or ""
	if ctx_path == "" then
		return false, "Err Empty ContextPath."
	end
	local data, err = ngx.decode_args(string.format(fmtstr, ...))
	if err ~= nil then
		return false, err
	end
	data = string.format(fmtstr, ...)
	local resp, err = self:post_naming(ctx_path, data)
	if err ~= nil then
		return false, err
	end
	if not resp:is_success() then
		local ne, err = parse_vintage_err(resp)
		if err ~= nil then
			return false, err
		end
		return false, ne
	end
	return resp.body
end


-- / ----------------------------- X ----------------------------- naming_admin ----------------------------- X ---------------------------- / --
function _M:naming_service_watch(service_name, cluster_name)
	local service_name, cluster_name
		= service_name or ""
		, cluster_name or ""
	if service_name == ""
	or cluster_name == "" then
		ngx.log(ngx.ERR, "naming_service_watch Err: empty parameter.")
		return nil, "naming_service_watch Err: empty parameter."
	end

	local m = self.ns_watch_map[service_name]
	if m == nil then
		m = {}
		self.ns_watch_map[service_name] = m
	end
	local chan = m[cluster_name]
	local watch_timer
	local watch_timer_key = get_timer_key(
		NAMING_SERVICE_WATCH_KEY,
		service_name, cluster_name)
	if chan == nil then
		watch_timer = timer:new(true, self.shm)
		chan = {
			service_name = service_name,
			cluster_name = cluster_name,
			watch_timer  = watch_timer,
			current_sign = ""
		}
		m[cluster_name] = chan		
		self:get_start_sign4watch(service_name, cluster_name)
		local ok, err = watch_timer:tick(
			watch_timer_key, self.heart_interval,
			self.check_changes,
			self, service_name, cluster_name)
		if not ok then
			return nil, err
		end
	else
		watch_timer = chan.watch_timer
		if watch_timer == nil then
			return nil, "Empty watch_timer"
		end
	end
	return {t=watch_timer,k=watch_timer_key}
end

function _M:get_start_sign4watch(service_name, cluster_name)
    if ngx.worker.id() == 0 then
        ngx.timer.at(0, function(premature, self, service_name, cluster_name)
			if not premature then
				local service_name, cluster_name = service_name, cluster_name
				local sn, err = self:remote_naming_service_lookup(service_name, cluster_name)
				if err ~= nil then
					ngx.log(ngx.INFO, "get_start_sign4watch err: \n", err)
					return nil, err
				end
				self.ns_watch_map[service_name][cluster_name]["current_sign"]
				= sn.sign
            end
        end, self, service_name, cluster_name)
    end
end

function _M:start_watch_cluster(service_name, cluster_name)
end

function _M:check_changes(service_name, cluster_name)
	local service_name, cluster_name
		= service_name or ""
		, cluster_name or ""
	if service_name == ""
	or cluster_name == "" then
		ngx.log(ngx.ERR, "naming_service_watch check_changes Err: empty parameter.")
		return nil, "naming_service_watch check_changes Err: empty parameter."
	end
	local m = self.ns_watch_map[service_name]
	if m == nil then
		return nil
	end
	local chan = m[cluster_name]
	if chan == nil then
		return nil
	end
	local sign = chan.current_sign
	sign = "x"
	local no_modified, sn, err = self:naming_service_lookup_for_update(service_name
	, cluster_name, sign)
	if err == nil and not no_modified and sn ~= nil then
		chan.current_sign = sn.sign
		-- @TODO need this?
		m[cluster_name] = chan
		return sn
	else
		return nil, err
	end
end

function _M:naming_service_unwatch(naming_service_watch_chan)
end

function _M:naming_service_unwatchAll(service_name)
end

function _M:clean_naming_service_watch()
end

return _M