-- Copyright (C) idevz (idevz.org)


local ipairs = ipairs
local singletons = require "motan.singletons"
local utils = require "motan.utils"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

local _get_default_msg_handler
_get_default_msg_handler = function()
    local _res = {
        _VERSION = '0.0.1'
    }
    local _mt = {__index = _res}
    function _res.new(_res_self)
        local _default_msg_handler = {
            providers = {}
        }
        return setmetatable(_default_msg_handler, _mt)
    end
    
    function _res.initialize(_res_self)
    end
    
    function _res.add_provider(_res_self, provider)
        _res_self.providers[provider:get_path()] = provider
    end
    
    function _res.rm_provider(_res_self, provider)
        local service_name = provider:get_path()
        if _res_self.providers[service_name] ~= nil then
            _res_self.providers[service_name] = nil
        end
    end
    
    function _res.get_provider(_res_self, service_name)
        local service_name = provider:get_path()
        return _res_self.providers[service_name] or false
    end
    
    function _res.call(_res_self, req)
        local req = req
        local provider = _res_self.providers[req:get_service_name()]
        return provider:call(req)
    end
    
    return _res:new()
end

local _get_filter_provider_warper
_get_filter_provider_warper = function(provider, filter)
    local _res = {
        _VERSION = '0.0.1'
    }
    local _mt = {__index = _res}
    function _res.new(_res_self, provider, filter)
        if utils.is_empty(provider) or utils.is_empty(filter) then
            ngx.log(ngx.ERR, "Err warper a provider with an empty provider or filter")
        end
        local _filter_provider_warper = {
            provider = provider, 
            filter = filter, 
            name = "filter_provider_warper"
        }
        return setmetatable(_filter_provider_warper, _mt)
    end
    
    function _res.set_service(_res_self, service)
        _res_self.provider:set_service(service)
    end
    
    function _res.get_url(_res_self)
        return provider:get_url()
    end
    
    function _res.set_url(_res_self, url)
        _res_self.provider:set_url(url)
    end
    
    function _res.get_path(_res_self)
        return _res_self.provider:get_path()
    end
    
    function _res.is_available(_res_self)
        return _res_self.provider.is_available()
    end
    
    function _res.destroy(_res_self)
        _res_self.provider.destroy()
    end
    
    function _res.call(_res_self, req)
        return _res_self.filter:filter(_res_self.provider, req)
    end
    
    return _res:new(provider, filter)
end

local _warp_provider_with_filter
_warp_provider_with_filter = function(provider)
    local last_filter = singletons.motan_ext:get_last_endpoint_filter()
    local provider_url = provider:get_url()
    local _, filters = provider_url:get_filters()
    
    for _, filter in ipairs(filters) do
        local nfilter = filter:new_filter(provider_url)
        nfilter:set_next(last_filter)
        last_filter = nfilter
    end
    return _get_filter_provider_warper(provider, last_filter)
end

function _M.new(self, url)
    local provider = singletons.motan_ext:get_provider(url)
    local warpered_provider = _warp_provider_with_filter(provider)
    -- warpered_provider:set_service(service_obj)
    local handler = _get_default_msg_handler()
    handler:add_provider(warpered_provider)
    local service = {
        url = url, 
        handler = handler
    }
    return setmetatable(service, mt)
end

return _M