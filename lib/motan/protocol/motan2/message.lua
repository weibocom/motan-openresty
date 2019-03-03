-- Copyright (C) idevz (idevz.org)

local setmetatable = setmetatable
local utils = require "motan.utils"

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M.new(self, opts)
    local msg = {
        header = opts.header or {},
        metadata = opts.metadata or {},
        body = opts.body or nil
    }
    return setmetatable(msg, mt)
end

function _M.get_header(self)
    return self.header
end

function _M.get_metadata(self)
    return self.metadata
end

function _M.get_body(self)
    return self.body
end

function _M.get_service_key(self)
    local group = self.metadata["M_g"]
    local version = self.header:get_version()
    local protocol = self.metadata["M_pp"]
    local path = self.metadata["M_p"]
    return utils.build_service_key(group, version, protocol, path)
end

return _M
