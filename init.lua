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
local consts = require "motan.consts"
local singletons = require "motan.singletons"

local Motan = {}

function Motan.init(sys_conf, motan_ext_set)
    local conf = require "motan.core.sysconf"
    local service = require "motan.server.service"
    local conf_obj = conf:new(sys_conf)
    singletons.config = conf_obj
    
    local motan_var = {}
    motan_var["LOCAL_IP"] = utils.get_local_ip()
    singletons.var = motan_var
    
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
        service_key = utils.build_service_key(info.group, info.params["version"], 
        info.protocol, info.path)
        service_map[service_key] = service:new(info)
    end
    singletons.service_map = service_map
end

function Motan.init_worker_motan_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "Caution: Server Could only use under stream subsystem.")
        return
    end
    local service_map = singletons.service_map
    local server_regstry = singletons.server_regstry
    local exporter = require "motan.server.exporter"
    local exporter_obj = exporter:new(service_map, server_regstry)
    exporter_obj:export()
end

function Motan.init_worker_motan_client()
    local client = require "motan.client"
    local referer_map = singletons.referer_map
    local client_map = {}
    for k, ref_url_obj in pairs(referer_map) do
        client_map[k] = client:new(ref_url_obj)
    end
    singletons.client_map = client_map
end

function Motan.preread()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "Caution: preread Could only use under stream subsystem.")
        return
    end
end

function Motan.content_motan_server()
    if ngx.config.subsystem ~= "stream" then
        ngx.log(ngx.ERR, "Caution: Server Could only use under stream subsystem.")
        return
    end
    local err_count = 1
    local server = require "motan.server"
    local service_map = singletons.service_map
    local sock = assert(ngx.req.socket(true))
    local server_obj = server:new{
        sock = sock, 
        service_map = service_map
    }
    local buf = ""
    
    while not ngx.worker.exiting() do
        local buf, err = server_obj:invoker()
        if not buf then
            err_count = err_count + 1
            return nil, err
        end
        if err_count > 3 then
            break
        end
        local bytes, err = sock:send(buf)
        if not bytes then
            break
        end
    end
end

function Motan.access()
end

function Motan.content_motan_client_test()
    local serialize = require "motan.serialize.simple"
    local client_map = singletons.client_map
    local client = client_map["rpc_test"]
    local res = client:show_batch({name = "idevz"})
    print_r("<pre/>")
    print_r(serialize.deserialize(res.body))
    local client2 = client_map["rpc_test_java"]
    local res2 = client2:hello("<-----Motan")
    print_r(serialize.deserialize(res2.body))
end

return Motan