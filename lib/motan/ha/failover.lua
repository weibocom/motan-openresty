-- Copyright (C) idevz (idevz.org)

local setmetatable = setmetatable
local singletons = require "motan.singletons"

local _M = {
    _VERSION = "0.1.0"
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

function _M.set_url(self, url) --luacheck:ignore
end

function _M.call(self, req, lb)
    local endpoint = lb:select(req)

    if not endpoint then
        local protocol = singletons.motan_ext:get_protocol(self.url["protocol"])
        return protocol:build_error_resp("None endpoint got.", req)
    end

    local resp = endpoint:call(req)
    return resp
end

return _M
