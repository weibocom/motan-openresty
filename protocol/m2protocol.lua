-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local null = ngx.null
local escape_uri = ngx.escape_uri
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local url = {}
    return setmetatable(url, mt)
end

return _M
