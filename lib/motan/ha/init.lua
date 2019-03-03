-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = "0.1.0"
}

function _M.regist_default_ha(ext)
    local failover_ha = require "motan.ha.failover"
    ext:regist_ext_ha("failover", function(url)
        return failover_ha:new(url)
    end)
end

return _M
