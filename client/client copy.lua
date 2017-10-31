-- Copyright (C) idevz (idevz.org)


local sub = string.sub
local byte = string.byte
local tcp = ngx.socket.tcp
local null = ngx.null
local type = type
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local rawget = rawget
--local error = error


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 54)

_M._VERSION = '0.0.1'

-- local _M = {
--     _VERSION = '0.07'
-- }

local mt = { __index = _M}


function _M.new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({ _sock = sock }, mt)
end


function _M.set_timeout(self, timeout)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end


function _M.connect(self, ...)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    self._subscribed = false

    return sock:connect(...)
end

function _do_call(self, fucname, ...)
    print_r(self)
    print_r(fucname)
    print_r(...)
end

setmetatable(_M, {__index = function(self, fucname)
    local method =
        function (self, ...)
            return _do_call(self, fucname, ...)
        end
    _M[fucname] = method
    return method
end})

return _M
