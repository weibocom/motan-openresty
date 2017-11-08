-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local parse = require "motan.config.parse"
local save = require "motan.config.save"

local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    local config_handle = {
        cpath = opts.cpath or "", 
        ctype = opts.ctype or "ini", 
    }
    return setmetatable(config_handle, mt)
end

function _M.get(self, conf)
    local lines = function(name) return assert(io.open(name)):lines() end
    return parse[self.ctype](lines, self.cpath .. '/' .. conf)
end

function _M.save(self, name, t)
    local write = function(name, contents) return assert(io.open(name, "w")):write(contents) end
    save[self.ctype](write, self.cpath .. '/' .. name, t)
    return true
end

return _M