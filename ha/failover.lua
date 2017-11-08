-- Copyright (C) idevz (idevz.org)


local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, url)
    local failover = {
        url = url, 
        name = "failover"
    }
    return setmetatable(failover, mt)
end

function _M.get_name(self)
    return self.name
end

function _M.get_url(self)
end

function _M.set_url(self, url)
end

function _M.call(self, req, lb)
    local lb = lb
    local endpoint = lb:select(req)
    local resp = endpoint:call(req)
    return resp
end

return _M
