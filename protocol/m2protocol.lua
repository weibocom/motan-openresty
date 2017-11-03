-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local url = {}
    return setmetatable(url, mt)
end

return _M
