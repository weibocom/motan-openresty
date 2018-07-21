-- Copyright (C) idevz (idevz.org)

local ext_lib = require "motan.core.ext"
local endpoint = require "motan.endpoint"
local provider = require "motan.provider"
local filter = require "motan.filter"
local ha = require "motan.ha"
local lb = require "motan.lb"
local serialize = require "motan.serialize"
local protocol = require "motan.protocol"
local registry = require "motan.registry"
local utils = require "motan.utils"

local _M = {
    _VERSION = "0.0.1",
    _DEFAULT_EXT = {}
}

local _add_default_ext
_add_default_ext = function(ext)
    endpoint.regist_default_endpoint(ext)
    provider.regist_default_provider(ext)
    registry.regist_default_registry(ext)
    filter.regist_default_filter(ext)
    ha.regist_default_ha(ext)
    lb.regist_default_lb(ext)
    serialize.regist_default_serializations(ext)
    protocol.regist_default_protocol(ext)
end

function _M.get_default_ext_factory()
    if utils.is_empty(_M._DEFAULT_EXT) then
        _M._DEFAULT_EXT = ext_lib:new()
        _add_default_ext(_M._DEFAULT_EXT)
    end
    return _M._DEFAULT_EXT
end

return _M
