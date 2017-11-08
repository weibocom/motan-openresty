-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local null = ngx.null
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

-- @TODO add metadata to service_instance when new
function _M.new(self, opts)
    local benchmark = {}
    return setmetatable(benchmark, mt)
end

function _M.echoService(self, opts)
	return opts
end

function _M.emptyService()
	return
end

return _M
