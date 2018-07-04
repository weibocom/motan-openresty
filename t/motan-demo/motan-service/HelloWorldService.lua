-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
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
    return "motan_openresty_helloworld_test_Hello_ok_" .. p1 .. p2
end

function _M.ConcurrentHello(self, p1, p2)
    
    ngx.log(ngx.ERR, "=====request_header(motan_metadata)======" .. sprint_r(self.metadata)  .. sprint_r(p1) .. "\n" .. sprint_r(p2))
    return self.metadata
end

return _M
