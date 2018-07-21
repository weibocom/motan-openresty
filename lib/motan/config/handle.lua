-- Copyright (C) idevz (idevz.org)

local parse = require "motan.config.parse"
local save = require "motan.config.save"
local setmetatable = setmetatable

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M.new(self, opts)
    local config_handle = {
        cpath = opts.cpath or "",
        ctype = opts.ctype or "ini"
    }
    return setmetatable(config_handle, mt)
end

function _M.get(self, conf)
    local lines = function(name)
        return assert(io.open(name)):lines()
    end
    return parse[self.ctype](lines, self.cpath .. "/" .. conf)
end

function _M.save(self, name, t)
    local write = function(fname, contents)
        return assert(io.open(fname, "w")):write(contents)
    end
    save[self.ctype](write, self.cpath .. "/" .. name, t)
    return true
end

return _M
