-- Copyright (C) idevz (idevz.org)


local utils = require "motan.utils"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new()
    local ext = {
        filter_fctrs = {}, 
        ha_fctrs = {}, 
        lb_fctrs = {}, 
        serialize_fctrs = {}, 
        protocol_fctrs = {}, 
        endpoint_fctrs = {}, 
        provider_fctrs = {}, 
        registry_fctrs = {}, 
        registries = {}, 
    }
    return setmetatable(ext, mt)
end

local _new_index
_new_index = function(self, key, name, func)
    if type(func) ~= "function" then
        local err_msg = "None function for ext " .. key .. ": " .. name
        ngx.log(ngx.ERR, err_msg)
        return nil, err_msg
    end
    self[key][name] = func
    return true, nil
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_filter(self, name, func)
    return _new_index(self, "filter_fctrs", name, func)
end

function _M.get_filter(self, name)
    local key = utils.trim(name)
    local new_filter = self.filter_fctrs[key]
    if new_filter ~= nil then
        return new_filter()
    end
    ngx.log(ngx.ERR, "Didn't have a filter: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_ha(self, name, func)
    return _new_index(self, "ha_fctrs", name, func)
end

function _M.get_ha(self, url)
    local key = url.params["haStrategy"]
    local new_ha = self.ha_fctrs[key]
    if new_ha ~= nil then
        return new_ha(url)
    end
    ngx.log(ngx.ERR, "Didn't have a ha: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_lb(self, name, func)
    return _new_index(self, "lb_fctrs", name, func)
end

function _M.get_lb(self, url)
    local key = url.params["loadbalance"]
    local new_lb = self.lb_fctrs[key]
    if new_lb ~= nil then
        return new_lb(url)
    end
    ngx.log(ngx.ERR, "Didn't have a lb: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_serialization(self, name, func)
    return _new_index(self, "serialize_fctrs", name, func)
end

function _M.get_serialization(self, name)
    local key = name
    local new_serialize = self.serialize_fctrs[key]
    if new_serialize ~= nil then
        return new_serialize()
    end
    ngx.log(ngx.ERR, "Didn't have a serialization: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_protocol(self, name, func)
    return _new_index(self, "protocol_fctrs", name, func)
end

function _M.get_protocol(self, protocol_name)
    local key = protocol_name
    local new_protocol = self.protocol_fctrs[key]
    if new_protocol ~= nil then
        return new_protocol()
    end
    ngx.log(ngx.ERR, "Didn't have a protocol: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_endpoint(self, name, func)
    return _new_index(self, "endpoint_fctrs", name, func)
end

function _M.get_endpoint(self, url)
    local key = url.protocol
    local new_endpoint = self.endpoint_fctrs[key]
    if new_endpoint ~= nil then
        return new_endpoint(url)
    end
    ngx.log(ngx.ERR, "Didn't have a endpoint: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_provider(self, name, func)
    return _new_index(self, "provider_fctrs", name, func)
end

function _M.get_provider(self, url)
    local key = url.params["provider"]
    local new_provider = self.provider_fctrs[key]
    if new_provider ~= nil then
        return new_provider(url)
    end
    ngx.log(ngx.ERR, "Didn't have a endpoint: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_registry(self, name, func)
    return _new_index(self, "registry_fctrs", name, func)
end

function _M.get_registry(self, url)
    local key = url:get_identity()
    local registries_cache = self.registries[key] or {}
    if registries_cache[self.registries[key]] ~= nil then
        return registries_cache
    else
        local registry = self.registry_fctrs[url.protocol]
        if registry ~= nil then
            registry_obj = registry(url)
            self.registries[key] = registry_obj
            return registry_obj
        else
            ngx.log(ngx.ERR, "Didn't have a registry: " .. key)
            return nil
        end
    end
end


--+--------------------------------------------------------------------------------+--
function _M.get_last_cluster_filter(self)
    local _res = {
        _VERSION = '0.0.1'
    }
    
    local mt = {__index = _res}
    
    function _res.new(_res_self)
        local last_cluster_filter = {
            name = "last_cluster_filter"
        }
        return setmetatable(last_cluster_filter, mt)
    end
    
    function _res.get_index(_res_self)
        return 100
    end
    
    function _res.get_name(_res_self)
        return _res_self.name
    end
    
    function _res.new_filter(_res_self, url)
    end
    
    function _res.filter(_res_self, ha, lb, req)
        return ha:call(req, lb)
    end
    
    function _res.has_next(_res_self)
        return false
    end
    
    function _res.set_next(_res_self, next_filter)
        ngx.log(ngx.ERR, "Couldn't set next filter to last_cluster_filter.\n")
    end
    
    function _res.get_next(_res_self)
        return nil
    end
    
    function _res.get_type(_res_self)
        return consts.MOTAN_FILTER_TYPE_CLUSTER
    end
    
    return _res:new()
end


--+--------------------------------------------------------------------------------+--
function _M.get_last_endpoint_filter(self)
    local _res = {
        _VERSION = '0.0.1'
    }
    
    local mt = {__index = _res}
    
    function _res.new(_res_self)
        local last_endpoint_filter = {
            name = "last_endpoint_filter"
        }
        return setmetatable(last_endpoint_filter, mt)
    end
    
    function _res.get_index(_res_self)
        return 100
    end
    
    function _res.get_name(_res_self)
        return _res_self.name
    end
    
    function _res.new_filter(_res_self, url)
    end
    
    function _res.filter(_res_self, caller, req)
        return caller:call(req, req)
    end
    
    function _res.has_next(_res_self)
        return false
    end
    
    function _res.set_next(_res_self, next_filter)
        ngx.log(ngx.ERR, "Couldn't set next filter to last_endpoint_filter.\n")
    end
    
    function _res.get_next(_res_self)
        return nil
    end
    
    function _res.get_type(_res_self)
        return consts.MOTAN_FILTER_TYPE_ENDPOINT
    end
    
    return _res:new()
end

return _M
