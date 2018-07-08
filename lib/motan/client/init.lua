-- Copyright (C) idevz (idevz.org)


local setmetatable = setmetatable
local cluster = require "motan.cluster"
local singletons = require "motan.singletons"
local utils = require "motan.utils"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, ref_url_obj)
    local cluster_obj = cluster:new(ref_url_obj)
    cluster_obj:init()
    local client = {
        url = ref_url_obj, 
        cluster = cluster_obj
    }
    return setmetatable(client, mt)
end

-- for calling with metadata
function _M.call(self, fucname, metadata, ...)
    local protocol = singletons.motan_ext:get_protocol(self.url.protocol)
    local req = protocol:make_motan_request(self.url, fucname, ...)
    if not utils.is_empty(metadata) then
        for k, v in pairs(metadata) do
            req:set_attachment(k, v)
        end
    end
    local resp = self.cluster:call(req)
    if resp:get_exception() ~= nil then
        return nil, resp:get_exception()
    end
    return resp.value
end

-- for purge RPC call
local _do_call
_do_call = function(self, fucname, ...)
    local protocol = singletons.motan_ext:get_protocol(self.url.protocol)
    local req = protocol:make_motan_request(self.url, fucname, ...)
    local resp = self.cluster:call(req)
    if resp:get_exception() ~= nil then
        return nil, resp:get_exception()
    end
    return resp.value
end

setmetatable(_M, {__index = function(self, fucname)
    local method = 
    function (self, ...)
        return _do_call(self, fucname, ...)
    end
    _M[fucname] = method
    return method
end})

return _M
