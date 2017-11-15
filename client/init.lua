-- Copyright (C) idevz (idevz.org)


local setmetatable = setmetatable
local consts = require "motan.consts"
local cluster = require "motan.cluster"
local simple = require "motan.serialize.simple"
local message = require "motan.protocol.motan2.message"
local m2codec = require "motan.protocol.motan2.codec"
local singletons = require "motan.singletons"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, ref_url_obj)
    local cluster_obj = cluster:new(ref_url_obj)
    cluster_obj:init()
    local client = {
        url = ref_url_obj, 
        cluster = cluster_obj, 
        response = {}
    }
    return setmetatable(client, mt)
end

function _do_call(self, fucname, ...)
    local protocol = singletons.motan_ext:get_protocol(self.url.protocol)
    local req = protocol:make_motan_request(self.url, fucname, ...)
    self.response = self.cluster:call(req)
    return self.response.value
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
