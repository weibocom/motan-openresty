-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
}

function _M.regist_default_lb(ext)
    local random_lb = require "motan.lb.random"
    ext:regist_ext_lb("random", function(url)
        return random_lb:new(url)
    end)
end

return _M
