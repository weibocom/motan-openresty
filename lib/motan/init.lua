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

local ngx = ngx
local assert = assert
local utils = require "motan.utils"
local singletons = require "motan.singletons"

local Motan = {
    _VERSION = '0.0.1'
}

local init_env
init_env = function()
    local APP_ROOT = string.sub(package.path, 1, string.find(package.path, [[//]]))
    local motan_env = os.getenv("MOTAN_ENV") or "production"
    if motan_env == "development" then
        singletons.is_dev = true
    end

    local motan_var = {}
    motan_var["LOCAL_IP"] = utils.get_local_ip()
    motan_var["APP_ROOT"] = APP_ROOT
    motan_var["ENV_STR"]  = motan_env
    singletons.var = motan_var
end

function Motan.init(motan_ext_set)
    init_env()
    local sys_conf = require("env." .. singletons.var["ENV_STR"])
    local conf = require "motan.core.sysconf"
    local service = require "motan.server.service"
    local conf_obj = conf:new(sys_conf)
    singletons.config = conf_obj
    
    local motan_ext = {}
    if utils.is_empty(motan_ext_set) then
        motan_ext = require("motan.motan_ext").get_default_ext_factory()
    else
        motan_ext = motan_ext_set
    end
    singletons.motan_ext = motan_ext
    
    local referer_map, client_regstry = conf_obj:get_client_conf()
    singletons.referer_map = referer_map
    singletons.client_regstry = client_regstry
    
    local service_map_tmp, server_regstry = conf_obj:get_server_conf()
    singletons.server_regstry = server_regstry
    
    -- @TODO newtab()
    local service_map = {}
    local service_key = ""
    for _, info in pairs(service_map_tmp) do
        service_key = utils.build_service_key(info.group, 
        info.params["version"], info.protocol, info.path)
        service_map[service_key] = service:new(info)
    end
    singletons.service_map = service_map
end

function Motan.init_worker_motan_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, 
        "Caution: Server Could only use under stream subsystem.")
        return
    end
    local exporter = require "motan.server.exporter"
    local exporter_obj = exporter:new()
    exporter_obj:export()
    exporter_obj:heartbeat()
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
        ngx.log(ngx.ERR, 
        "Caution: preread Could only use under stream subsystem.")
        return
    end
end

function Motan.content_motan_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, 
        "Caution: Server Could only use under stream subsystem.")
        return
    end
    local server = require "motan.server"
    local motan_server = server:new()
    motan_server:run()
end

function Motan.access()
end

function Motan.content_motan_client_test()
    local serialize = require "motan.serialize.simple"
    local client_map = singletons.client_map
    local client = client_map["rpc_test"]
    local http_method = ngx.req.get_method()
    local params = {}
    params = ngx.req.get_uri_args()
    if http_method == "POST" then
        ngx.req.read_body()
        local post_args = ngx.req.get_post_args()
        for k,v in pairs(post_args) do
            params[k] = v
        end
    end
    params["http_method"] = http_method
    local res = client:show_batch(params)
    ngx.header["X-IDEVZ"] = 'idevz-k-49';
    print_r("<pre/>")
    print_r(res)
    print_r(ngx.req.get_headers())
    print_r(client.response)
    -- print_r(serialize.deserialize(res.body))
    -- local client2 = client_map["rpc_test_java"]
    -- local res2 = client2:hello("<-----Motan")
    -- print_r(serialize.deserialize(res2.body))
end

return Motan