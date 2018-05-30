-- Copyright (C) idevz (idevz.org)


local pairs = pairs
local assert = assert
local setmetatable = setmetatable
local motan_consul = require "motan.registry.consul"
local singletons = require "motan.singletons"
local consts = require "motan.consts"
local utils = require "motan.utils"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M:new()
    local exporter = {
        heartbeat_map = {}
    }
    return setmetatable(exporter, mt)
end

function _M:export()
    local service_map = singletons.service_map
    local server_regstry = singletons.server_regstry
    for service_key, service_obj in pairs(service_map) do
        local service_url_obj = service_obj.url
        local registry_keys = service_url_obj.params.registry or nil
        if registry_keys == nil then
            ngx.log(ngx.ERR, 
            "Empty registry configure error: \n Error service:", 
            service_url_obj:get_identity())
            return
        end
        local registry_arr = utils.split(registry_keys, ",")
        for _, registry_url_key in ipairs(registry_arr) do
            local registry_url_obj = server_regstry[registry_url_key]
            local registry_obj = singletons.motan_ext:get_registry(registry_url_obj)
            registry_obj:register(service_url_obj)
            if self.heartbeat_map[registry_obj] == nil then
                self.heartbeat_map[registry_obj] = {}
            end
            table.insert(self.heartbeat_map[registry_obj], service_url_obj)
        end
    end
end

function _M:heartbeat()
    local heartbeat_map = self.heartbeat_map
    for registry_obj, service_url_obj_arr in pairs(heartbeat_map) do
        registry_obj:heartbeat(service_url_obj_arr)
    end
end

return _M