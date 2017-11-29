-- Copyright (C) idevz (idevz.org)


local singletons = require "motan.singletons"
local response = require "motan.core.response"
local utils = require "motan.utils"
local setmetatable = setmetatable
local math = math

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, url)
    local motan_provider = {
        url = url, 
        service_obj_arr = {}, 
        service = {}
    }
    return setmetatable(motan_provider, mt)
end

function _M.initialize(self)
end

function _M.set_service(self, service)
    self.service = service
end

function _M.get_url(self)
    return self.url
end

function _M.set_url(self, url)
    self.url = url
end

function _M.get_path(self)
    return self.url.path
end

function _M.is_available(self)
    return true
end

function _M.destroy(self)
end

function _M.get_service_obj(self, url)
    local url = url
    local service_obj_key = url:get_identity()
    local service_obj = self.service_obj_arr[service_obj_key] or {}
    if not utils.is_empty(service_obj) then
        return service_obj
    end
    local service_path_conf = singletons.config.conf_set["SERVICE_PATH"] or nil
    if service_path_conf == nil then
        ngx.log(ngx.ERR, "SERVICE_PATH didn't set.\n")
        return
    end
    local service_file = ""
    local service_prefix
    service_prefix = singletons.config.conf_set["MOTAN_LUA_SERVICE_PERFIX"]
    if service_prefix ~= nil then
        local ss = url.path
        local s, e = string.find(ss, service_prefix)
        if not s then
            return nil
            , "build service Err: service path didn't contain service_prefix."
        end
        service_file = service_path_conf .. "/" .. string.sub(ss, e + 1)
    else
        service_file = service_path_conf .. "/" .. url.path
    end
    
    local service_pkg = assert(require(service_file)
    , "Load service package err. File:\n" .. service_file)
    local service_obj = assert(service_pkg:new()
    , "Init Service object err. File:\n" .. service_file)
    self.service_obj_arr[service_obj_key] = service_obj
    return service_obj
end

function _M.call(self, req)
    local start_time = ngx.now()
    local value, exception = nil, nil
    local service = self:get_service_obj(self.url)
    local resp_obj = {}
    local method = req:get_method()
    local ok, res = pcall(service[method], service, req:get_arguments())
    local request_id = req:get_request_id()
    
    if ok then
        value = res
    else
        ngx.log(ngx.ERR, "Provider Call Err " .. res)
        exception = "Provider Call Err " .. res
        return response:new{
            request_id = request_id, 
            exception = exception, 
        }
    end
    local process_time = ngx.now() - start_time
    local attachment = req:get_attachments()
    
    return response:new{
        request_id = request_id, 
        value = value, 
        exception = exception, 
        process_time = math.floor((process_time * 100) + 0.5) * 0.01, 
        attachment = attachment
    }
end

return _M
