--- Created by minggang
--- DateTime: 2018/5/10 15:29
----- Copyright (C) idevz (idevz.org)
----- Copyright (C) minggang

local setmetatable = setmetatable
local tab_insert = table.insert

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M:new(opts)
    local direct = {
        host = opts.host,
        port = opts.port
    }
    return setmetatable(direct, mt)
end

function _M:get_name()
    return "directRegistry"
end

function _M:get_url()
end

function _M:set_url(url) --luacheck:ignore
end

function _M:subscribe(url, listener)
    listener:_notify(url, self:discover(url))
end

function _M:unsubscribe(url, listener) --luacheck:ignore
end

function _M:discover(url)
    local res = {}
    local endpoint_url =
        url:new {
        protocol = url.protocol,
        host = self.host,
        port = self.port,
        path = url.path,
        group = url.group,
        params = url.params
    }
    tab_insert(res, endpoint_url)
    return res
end

function _M:subscribe_command(url, listener) --luacheck:ignore
end

function _M:unsubscribe_command(url, listener) --luacheck:ignore
end

function _M:discover_command(url) --luacheck:ignore
end

function _M:heartbeat(service_url_obj_arr) --luacheck:ignore
end

function _M:register(server_url) --luacheck:ignore
end

function _M:unregister(server_url) --luacheck:ignore
end

function _M:available(server_url) --luacheck:ignore
end

function _M:unavailable(server_url) --luacheck:ignore
end

function _M:get_registered_services()
end

function _M:start_snapshot(conf) --luacheck:ignore
end

return _M
