-- Copyright (C) idevz (idevz.org)


local pairs = pairs
local assert = assert
local setmetatable = setmetatable
local motan_consul = require "motan.registry.consul"
local singletons = require "motan.singletons"
local consts = require "motan.consts"
local utils = require "motan.utils"
local sprint_r = utils.sprint_r

local _get_consul_obj
_get_consul_obj = function(registry_info)
    return motan_consul:new{
        host = registry_info.host, 
        port = registry_info.port, 
    }
end

local _to_register = function(registry_info, service_url_obj)
    local c_obj = _get_consul_obj(registry_info)
    c_obj:do_register(service_url_obj)
end

local _do_heartbeat
_do_heartbeat = function(premature, heartbeat_map)
    if premature then
        return
    end
    for service_key, heartbeat_info in pairs(heartbeat_map) do
        local c_obj = _get_consul_obj(heartbeat_info.registry_info)
        c_obj:check_pass(heartbeat_info.service_url_obj)
    end
    local ok, err = ngx.timer.at(consts.MOTAN_CONSUL_HEARTBEAT_PERIOD
    , _do_heartbeat, heartbeat_map)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the _do_register timer: ", err)
        return
    end
end

local _do_register
_do_register = function(premature, self)
    if premature then
        return
    end
    
    local heartbeat_map = {}
    for service_key, service_obj in pairs(self.service_map) do
        local service_url_obj = service_obj.url
        heartbeat_map[service_key] = {}
        local registry_key = service_url_obj.params.registry or nil
        if registry_key then
            local registry_info = assert(self.server_regstry[registry_key]
            , "Empty registry config: " .. registry_key)
            if not utils.is_empty(registry_info) then
                _to_register(registry_info, service_url_obj)
                heartbeat_map[service_key] = {
                    registry_info = registry_info, 
                    service_url_obj = service_url_obj, 
                }
            end
        end
    end
    ngx.log(ngx.INFO, "Service registry: \n" .. sprint_r(heartbeat_map))
    local ok, err = ngx.timer.at(0, _do_heartbeat, heartbeat_map)
    if not ok then
        ngx.log(ngx.ERR, "failed to create the _do_register timer: ", err)
        return
    end
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self)
    local service_map = singletons.service_map
    local server_regstry = singletons.server_regstry
    local exporter = {
        service_map = service_map, 
        server_regstry = server_regstry
    }
    return setmetatable(exporter, mt)
end

function _M.export(self)
    ngx.timer.at(0, _do_register, self)
end

return _M