-- Copyright (C) idevz (idevz.org)


local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, url)
    local random = {
        url = url,
        endpoints = {},
        weight = ""
    }
    return setmetatable(random, mt)
end

function _M.on_refresh(self, endpoints)
    -- body
end

function _M.on_refresh(self, endpoints)
end

function _M.select(self, req)
end

function _M.select_array(self, req)
end

function _M.set_weight(self, weight)
end

function _M.select_index(self, req)
end

return _M
