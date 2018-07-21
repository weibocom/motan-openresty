-- Copyright (C) idevz (idevz.org)

local setmetatable = setmetatable

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M.new(self, opts)
    local url = {
        protocol = opts.protocol or "",
        host = opts.host or "",
        port = opts.port or 0,
        path = opts.path or "",
        group = opts.group or "",
        params = opts.params or {}
    }
    return setmetatable(url, mt)
end

return _M
