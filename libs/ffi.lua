-- Copyright (C) idevz (idevz.org)

package.path = [[/?.lua;/?/init.lua;/media/psf/g/idevz/code/www/vanilla/framework/?.lua;/media/psf/g/idevz/code/www/vanilla/framework/?/init.lua;]] .. package.path

local helpers = require "motan.utils"

function sprint_r( ... )
    return helpers.sprint_r(...)
end

function lprint_r( ... )
    local rs = sprint_r(...)
    print(rs)
end

function print_r( ... )
    local rs = sprint_r(...)
    ngx.say(rs)
end

local ffi = require "ffi"
local motan_tools = ffi.load('motan_tools')

ffi.cdef[[
int get_local_ip(char *, char *);
]]

-- local c_str_t = ffi.typeof("const char*")
local c_str_t = ffi.typeof("char[4]")

local eth0_info = "eth0"
local eth0 = ffi.new(c_str_t)
ffi.copy(eth0, eth0_info)

local ip = ffi.new("char[32]")
local local_ip = motan_tools.get_local_ip(eth0, ip)
print(ffi.string(eth0))
print(ffi.string(ip))

-- print(package.path)

local ext = require("motan.motan_ext").get_default_ext_factory()

lprint_r(ext)

lprint_r(ext:getEndpoint("Motan2"))