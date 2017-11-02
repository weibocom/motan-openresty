-- Copyright (C) idevz (idevz.org)


local setmetatable = setmetatable
local message = require "motan.protocol.message"
local m2codec = require "motan.protocol.m2codec"
local consts = require "motan.consts"
local simple = require "motan.serialize.simple"

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local client = {
        url = opts.url or {},
        cluster = opts.cluster or {},
        ext_fact = opts.ext or {},
    }
    return setmetatable(client, mt)
end

function _do_call(self, fucname, ...)
    local m2codec_obj = m2codec:new{
        msg_type = consts.MOTAN_MSG_TYPE_REQUEST,
    }
    local header = m2codec_obj:buildRequestHeader(555)
    local metadata = {
        M_p = self.url.path,
        M_m = fucname,
        M_g = self.url.group,
        M_pp = self.url.protocol,
    }
    local req_params = ...
    local req = message:new{
        header = header,
        metadata = metadata,
        body = simple.serialize(req_params),
    }
    return self.cluster:call(req)
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
