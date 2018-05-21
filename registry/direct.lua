--- Created by minggang
--- DateTime: 2018/5/10 15:29
----- Copyright (C) idevz (idevz.org)
----- Copyright (C) minggang


local setmetatable = setmetatable
local tab_insert = table.insert

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local direct = {
        host = opts.host,
        port = opts.port
    }
    return setmetatable(direct, mt)
end

function _M.do_register(self, url)
    ngx.log(ngx.INFO, "register url " .. url:get_identity())
end

function _M.check_pass(self, url)
end

function _M.get(self, ...)
end

function _M.subscribe(self, url, listener)
    listener:_notify(url, self:discover(url))
end

function _M.discover(self, url)
    local res = {}
    local endpoint_url = url:new {
        protocol = url.protocol,
        host = self.host,
        port = self.port,
        path = url.path,
        group = url.group,
        params = url.params,
    }
    tab_insert(res, endpoint_url)
    return res
end

return _M
