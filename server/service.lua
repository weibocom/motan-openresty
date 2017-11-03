-- Copyright (C) idevz (idevz.org)


local assert = assert
local consts = require "motan.consts"

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, url)
	local service_file = assert(url.params[consts.MOTAN_LUA_SERVICE_PACKAGE]
		, "Service package params is Empty. Url:\n" .. sprint_r(url))
	local service_pkg = assert(require(service_file)
		, "Load service package err. File:\n" .. service_file)
	local service_obj = assert(service_pkg:new()
		, "Init Service object err. File:\n" .. service_file)
    local service = {
        url = url,
        service_obj = service_obj
    }
    return setmetatable(service, mt)
end

return _M