-- Copyright (C) idevz (idevz.org)

local helpers = require "motan.utils"

function sprint_r(...)
    return helpers.sprint_r(...)
end

function lprint_r(...)
    local rs = sprint_r(...)
    print(rs)
end

function print_r(...)
    local rs = sprint_r(...)
    ngx.say(rs)
end

motan_ctx = function()
    do
        return ngx.ctx
    end
    local current_co = coroutine.running()
    if ngx.ctx[current_co] == nil then
        ngx.ctx[current_co] = {}
    end
    return ngx.ctx[current_co]
end

clean_motan_ctx = function()
    do
        return true
    end
    local current_co = coroutine.running()
    if ngx.ctx[current_co] ~= nil then
        local request_id = ngx.ctx[current_co].request_id or "--"
        ngx.ctx[current_co] = nil
        ngx.log(ngx.INFO, "clean motan ctx for request id:", request_id, ", ", tostring(current_co))
    end
    return true
end

local ngx = ngx
local utils = require "motan.utils"
local singletons = require "motan.singletons"

local Motan = {
    _VERSION = "0.1.0"
}

local init_env
init_env = function(default_env_setting)
    local default_env_setting = default_env_setting or {}
    local app_root = default_env_setting.APP_ROOT or os.getenv("APP_ROOT") or nil
    local motan_env = default_env_setting.MOTAN_ENV or os.getenv("MOTAN_ENV") or "production"
    assert(app_root ~= nil, "APP_ROOT should not be nil")
    if motan_env == "development" then
        singletons.is_dev = true
    end
    ngx.log(ngx.NOTICE, "motan openresty is running under:", motan_env, ", APP_ROOT is:", app_root)

    local motan_var = {}
    local local_ip = os.getenv("MOTAN_LOCAL_IP") or _G.MOTAN_LOCAL_IP
    if local_ip == nil then
        local local_host_resolve_addr = os.getenv("MOTAN_LOCAL_IP_RESOLVE_ADDR") or _G.MOTAN_LOCAL_IP_RESOLVE_ADDR
        if local_host_resolve_addr ~= nil then
            local host_and_port = utils.split(local_host_resolve_addr, ":")
            if #host_and_port > 1 then
                local host = host_and_port[1]
                local port = tonumber(host_and_port[2])
                local_ip = utils.get_local_ip_from_host_and_port(host, port)
            end
        end
        if local_ip == nil or local_ip == "" then
            local_ip = utils.get_local_ip()
        end
    end
    ngx.log(ngx.NOTICE, "get local ip is:", local_ip)
    motan_var["LOCAL_IP"] = local_ip
    motan_var["APP_ROOT"] = app_root
    motan_var["ENV_STR"] = motan_env
    singletons.var = motan_var
    math.randomseed(ngx.time())
end

function Motan.init(motan_ext_set, default_env_setting)
    init_env(default_env_setting)
    local sys_conf = require("env." .. singletons.var["ENV_STR"])
    local conf = require "motan.core.sysconf"
    local service = require "motan.server.service"
    local conf_obj = conf:new(sys_conf)
    singletons.config = conf_obj

    local motan_ext
    if utils.is_empty(motan_ext_set) then
        motan_ext = require("motan.motan_ext").get_default_ext_factory()
    else
        motan_ext = motan_ext_set
    end
    singletons.motan_ext = motan_ext

    local referer_map, client_registry = conf_obj:get_client_conf()
    singletons.referer_map = referer_map
    singletons.client_registry = client_registry

    local service_map_tmp, server_registry = conf_obj:get_server_conf()
    singletons.server_registry = server_registry

    -- @TODO newtab()
    local service_map = {}
    local service_key
    for _, url in pairs(service_map_tmp) do
        service_key = utils.build_service_key(url.group, url.params["version"], url.protocol, url.path)
        service_map[service_key] = service:new(url)
    end
    singletons.service_map = service_map
end

function Motan.init_worker_motan_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "caution: Server Could only use under stream subsystem.")
        return
    end
    local exporter = require "motan.server.exporter"
    local exporter_obj = exporter:new()
    exporter_obj:export()
    exporter_obj:heartbeat()

    local switch_server = require "motan.switch"
    local motan_switch_server = switch_server:new()
    motan_switch_server:start_check(exporter_obj)
end

function Motan.init_worker_motan_client()
    local client = require "motan.client"
    local referer_map = singletons.referer_map
    for k, ref_url_obj in pairs(referer_map) do
        singletons.client_map[k] = client:new(ref_url_obj)
    end
end

function Motan.preread()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "caution: preread Could only use under stream subsystem.")
        return
    end
end

function Motan.content_motan_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "caution: Server Could only use under stream subsystem.")
        return
    end
    local server = require "motan.server"
    local motan_server = server:new()
    motan_server:run()
end

function Motan.motan_switch_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "caution: Server Could only use under stream subsystem.")
        return
    end
    local switch_server = require "motan.switch"
    local motan_switch_server = switch_server:new()
    motan_switch_server:run()
end

function Motan.access()
end

function Motan.content_motan_client_test()
    -- local serialize = require "motan.serialize.simple"
    local client_map = singletons.client_map
    local client = client_map["rpc_test"]
    local http_method = ngx.req.get_method()
    local params = ngx.req.get_uri_args()
    if http_method == "POST" then
        ngx.req.read_body()
        local post_args = ngx.req.get_post_args()
        for k, v in pairs(post_args) do
            params[k] = v
        end
    end
    params["http_method"] = http_method
    local res = client:show_batch(params)
    ngx.header["X-IDEVZ"] = "idevz-k-49"
    print_r("<pre/>")
    print_r(res)
    print_r(ngx.req.get_headers())
    print_r(client.response)
    -- print_r(serialize.deserialize(res.body))
    -- local client2 = client_map["rpc_test_java"]
    -- local res2 = client2:hello("<-----Motan")
    -- print_r(serialize.deserialize(res2.body))
    -- motan_ctx().request_id_a =
    --     ngx.now() .. "---" .. ngx.worker.pid() .. "---" .. math.random(11111111, 99999999)
end

return Motan
