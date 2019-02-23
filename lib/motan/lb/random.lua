-- Copyright (C) idevz (idevz.org)

local setmetatable = setmetatable

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M.new(self, url)
    local random = {
        url = url,
        endpoints = {},
        name = "random",
        weight = ""
    }
    return setmetatable(random, mt)
end

function _M.on_refresh(self, endpoints)
    self.endpoints = endpoints
end

function _M.select(self, req) --luacheck:ignore
    local endpoints_temp = self.endpoints
    local endpoints_length = #endpoints_temp
    local ran = math.random(1, endpoints_length)
    for i = 1, endpoints_length do
        local index = (ran + i) % endpoints_length + 1
        local endpoint = endpoints_temp[index]
        if endpoint:is_available() then
            return endpoint
        end
    end
end

function _M.select_array(self, req) --luacheck:ignore
end

function _M.set_weight(self, weight) --luacheck:ignore
end

function _M.select_index(self, req) --luacheck:ignore
end

return _M
