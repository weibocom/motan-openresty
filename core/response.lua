-- Copyright (C) idevz (idevz.org)


local assert = assert
local consts = require "motan.consts"
local singletons = require "motan.singletons"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    local response = {
        sock = sock
    }
    return setmetatable(response, mt)
end

function _M.buildReq()
    -- body
end

return _M