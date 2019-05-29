-- Copyright (C) idevz (idevz.org)

local ngx_spawn = ngx.thread.spawn
local setmetatable = setmetatable
local math = math

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M.spawn(f, ...)
    return ngx_spawn(
        function(f, ...)
            if type(f) ~= "function" then
                return nil, error("thread spawn must need a function first.")
            end
            clean_motan_ctx()
            local res = {f(...)}
            clean_motan_ctx()
            return unpack(res)
        end,
        f,
        ...
    )
end

return _M
