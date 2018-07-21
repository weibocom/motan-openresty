-- Copyright (C) idevz (idevz.org)

local tcp = ngx.socket.tcp
local setmetatable = setmetatable
local rawget = rawget
local singletons = require "motan.singletons"
local consts = require "motan.consts"
local utils = require "motan.utils"
local json = require "cjson"

local MAX_IDLE_TIMEOUT = 30 * 1000 -- 30s default timeout
local POOL_SIZE = 100

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M.new(self, url)
    local motan_ep = {
        url = url,
        max_idle_timeout = consts.MOTAN2_EP_MAX_IDLE_TIMEOUT or MAX_IDLE_TIMEOUT,
        pool_size = consts.MOTAN2_EP_POOL_SIZE or POOL_SIZE,
        _sock = {}
    }
    return setmetatable(motan_ep, mt)
end

function _M.initialize(self)
end

function _M.destroy(self)
end

function _M.set_proxy(self, proxy) --luacheck:ignore
end

function _M.set_serialization(self, serialization) --luacheck:ignore
end

function _M.get_name(self)
end

function _M.get_url(self)
    return self.url
end

function _M.set_url(self, url) --luacheck:ignore
end

function _M.is_available(self)
    return true
end

function _M.set_timeout(self, timeout)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end

function _M.connect(self)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end
    local ok, err = sock:connect(self.url.host, self.url.port)
    if err ~= nil then
        ngx.log(ngx.ERR, "socket connection error")
    end
    local use_weibo_mesh = false
    if
        singletons.config.conf_set["WEIBO_MESH"] ~= nil and
            singletons.config.conf_set["WEIBO_MESH"] == table.concat({self.url.host, self.url.port}, ":")
     then
        use_weibo_mesh = true
    end
    if not ok and use_weibo_mesh then
        local res = ngx.location.capture("/snapshot/" .. self.url.group .. "_" .. self.url.path)
        if res.status == 200 then
            local working_nodes = {}
            local mesh_snapshot_for_server_nodes = json.decode(res.body)["nodes"]["working"]
            if not utils.is_empty(mesh_snapshot_for_server_nodes) then
                for _, node in ipairs(mesh_snapshot_for_server_nodes) do
                    table.insert(working_nodes, node)
                end
            end
            local cnct_node = working_nodes[math.random(#working_nodes)]["host"]
            local node_info = utils.split(cnct_node, ":")
            return sock:connect(node_info[1], node_info[2])
        else
            return nil, "motan endpoint failed connect to weibo mesh, and also couldn't get the snapshots."
        end
    end
    return sock:connect(self.url.host, self.url.port)
end

function _M.call(self, req)
    local start_time = ngx.now()
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    rawset(self, "_sock", sock)
    local ok, conn_err = self:connect()
    local protocol = singletons.motan_ext:get_protocol(self.url.protocol)
    if ok then
        local serialization
        serialization = singletons.motan_ext:get_serialization(self.url.params["serialization"])
        local req_buf = protocol:convert_to_request_msg(req, serialization)
        local bytes, send_err = sock:send(req_buf)
        if not bytes then
            ngx.log(ngx.ERR, "motan endpoint send RPC Call err: ", send_err)
            return protocol:build_error_resp(send_err, req)
        end
        local resp_ok, resp_err = protocol:read_reply(sock, serialization)
        if not resp_ok then
            ngx.log(ngx.ERR, "motan endpoint receive RPC resp err: ", resp_err)
            return protocol:build_error_resp(resp_err, req)
        end
        sock:setkeepalive(self.max_idle_timeout, self.pool_size)
        local process_time = ngx.now() - start_time
        resp_ok:set_process_time(math.floor((process_time * 100) + 0.5) * 0.01)
        return resp_ok
    else
        ngx.log(ngx.ERR, "motan endpoint failed connect to peer: ", conn_err)
        return protocol:build_error_resp(conn_err, req)
    end
end

return _M
