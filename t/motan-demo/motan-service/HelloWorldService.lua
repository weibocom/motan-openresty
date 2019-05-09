-- Copyright (C) idevz (idevz.org)

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

-- @TODO add metadata to service_instance when new
function _M.new(self, opts)
    local helloworld = {
        name = "helloworld"
    }
    return setmetatable(helloworld, mt)
end

function _M.Hello(self, p1, p2)
    ngx.log(ngx.ERR, sprint_r({p1, p2}))
    return "motan_openresty_helloworld_test_Hello_ok_" .. p1 .. p2
end

function _M.ConcurrentHello(self, p1, p2)
    ngx.log(ngx.ERR, "ConcurrentHello ===>", sprint_r({p1, p2}))
    return motan_ctx().metadata
end

return _M
