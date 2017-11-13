-- Copyright (C) idevz (idevz.org)


local assert = assert
local consts = require "motan.consts"
local singletons = require "motan.singletons"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    local request = {
        request_id = otps["request_id"] or nil,
        service_name = otps["service_name"] or nil,
        method = otps["method"] or nil,
        method_desc = otps["method_desc"] or nil,
        arguments = otps["arguments"] or {},
        attachment = otps["attachment"] or {},
    }
    return setmetatable(request, mt)
end

return _M