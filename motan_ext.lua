-- Copyright (C) idevz (idevz.org)


local ext = require "motan.core.ext"
local endpoint = require "motan.endpoint"
local registry = require "motan.registry"
local utils = require "motan.utils"

local _M = {
    _VERSION = '0.0.1',
    _ALL_READY_INIT = false,
    _DEFAULT_EXT = {}
}

function _add_default_ext(ext)
	endpoint.regist_default_endpoint(ext)
	registry.regist_default_registry(ext)
end

function _M.get_default_ext_factory()
	if utils.is_empty(_M._DEFAULT_EXT) then
		_M._DEFAULT_EXT = ext:new()
		_add_default_ext(_M._DEFAULT_EXT)
	end
	return _M._DEFAULT_EXT
end

return _M
