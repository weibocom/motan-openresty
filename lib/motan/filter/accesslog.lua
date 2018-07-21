-- Copyright (C) idevz (idevz.org)

local setmetatable = setmetatable
local consts = require "motan.consts"
local utils = require "motan.utils"

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M.new(self, url)
    local accessLog = {
        name = "accessLog",
        url = url or {},
        next = {}
    }
    return setmetatable(accessLog, mt)
end

function _M.get_index(self)
    return 1
end

function _M.get_name(self)
    return self.name
end

function _M.new_filter(self, url)
    return self:new(url)
end

function _M.filter(self, caller, req)
    local resp = self:get_next():filter(caller, req)
    return resp
end

function _M.has_next(self)
    return not utils.is_empty(self.next)
end

function _M.set_next(self, next_filter)
    self.next = next_filter
end

function _M.get_next(self)
    return self.next
end

function _M.get_type(self)
    return consts.MOTAN_FILTER_TYPE_ENDPOINT
end

function _M.is_available(self)
    if self.url.port == 8005 then
        return false
    end
    return true
end

return _M
