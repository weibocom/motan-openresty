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

function _M.Hello(self, params, aaa)
    return "motan_openresty_helloworld_test_ok"
end

return _M
