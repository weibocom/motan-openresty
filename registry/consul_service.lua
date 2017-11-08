-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    local consul_service = {
        id = opts.id or "", 
        name = opts.name or "", 
        tags = opts.tags or {}, 
        address = opts.address or "", 
        port = opts.port or 0, 
        ttl = opts.ttl or 0, 
    }
    return setmetatable(consul_service, mt)
end

function _M.to_new(self, opts)
    local check = {}
    for k, v in pairs(opts) do
        if v then
            check[k] = v
        end
    end
    -- local check = {
    -- Script = opts.Script or "",
    -- Interval = opts.Interval or "",
    -- TTL = opts.TTL or "",
    -- HTTP = opts.HTTP or "",
    -- TCP = opts.TCP or "",
    -- Timeout = opts.Timeout or "",
    -- DeregisterCriticalServiceAfter = opts.DeregisterCriticalServiceAfter or "",
    -- }
    self.Check = check
end

return _M
