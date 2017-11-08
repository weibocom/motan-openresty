-- Copyright (C) idevz (idevz.org)


local assert = assert
local consts = require "motan.consts"
local singletons = require "motan.singletons"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, url)
    local service_path_conf = singletons.config.conf_set["SERVICE_PATH"] or nil
    if service_path_conf == nil then
        ngx.log(ngx.ERR, "SERVICE_PATH didn't set.\n")
        return
    end
    local service_file = ""
    local MOTAN_LUA_SERVICE_PERFIX = singletons.config.conf_set["MOTAN_LUA_SERVICE_PERFIX"]
    if MOTAN_LUA_SERVICE_PERFIX ~= nil then
        local ss = url.path
        local s, e = string.find(ss, MOTAN_LUA_SERVICE_PERFIX)
        if not s then
            return nil, "build service Err: service path didn't contain MOTAN_LUA_SERVICE_PERFIX.\n"
        end
        service_file = service_path_conf .. "/" .. string.sub(ss, e + 1)
    else
    	service_file = service_path_conf .. "/" .. url.path
    end
    
    local service_pkg = assert(require(service_file)
    , "Load service package err. File:\n" .. service_file)
    local service_obj = assert(service_pkg:new()
    , "Init Service object err. File:\n" .. service_file)
    local service = {
        url = url, 
        service_obj = service_obj
    }
    return setmetatable(service, mt)
end

return _M