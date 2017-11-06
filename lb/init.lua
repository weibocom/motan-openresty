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
    local opt_type = type(opts)
    if opt_type == "table" then
        url = {
            protocol = opts.protocol or "",
            host = opts.host or "",
            port = opts.port or 0,
            path = opts.path or "",
            group = opts.group or "",
            params = opts.params or {},
        }
    elseif opt_type == "string" then
        -- @TODO
    end
    return setmetatable(url, mt)
end

function _M.get_identity(self)
    local url_info = self:get_urlinfo()
    return tab_concat(url_info)
end

return _M
