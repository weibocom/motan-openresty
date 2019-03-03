-- Copyright (C) idevz (idevz.org)


local client_t = require "resty.vintage.client"

local DEFAULT_TIMEOUT = 60*1000 -- 60s default timeout
local DEFAULT_HEART_INTERVAL  = 5

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M:new(shm, addr, timeout, heart_interval)
    local addr = addr or nil
    assert(addr ~= nil, "Vintage Registry addr must not be nil.")

	local shm = shm
    assert(shm ~= nil, "Vintage need a share dict to store nodes.")

    local timeout = timeout or DEFAULT_TIMEOUT
    local heart_interval = heart_interval or DEFAULT_HEART_INTERVAL
    
    local api_client = client_t:new{
        addr = addr,
        shm = shm,
        timeout = timeout,
        heart_interval = heart_interval,
    }
    local config_service_t = {
        api_client = api_client
    }
    return setmetatable(config_service_t, mt)
end

return _M