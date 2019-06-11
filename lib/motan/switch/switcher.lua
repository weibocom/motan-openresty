-- Copyright (C) idevz (idevz.org)

local consts = require "motan.consts"
local singletons = require "motan.singletons"

local _M = {
    _VERSION = "0.1.0"
}

_M[consts.MOTAN_SWITCHER_503] = function(switch_content)
    ngx.log(ngx.STDERR, "--------consts.MOTAN_SWITCHER_503--------", switch_content)
    switch_shm:set(consts.MOTAN_SWITCHER_503, switch_content)
end

return _M
