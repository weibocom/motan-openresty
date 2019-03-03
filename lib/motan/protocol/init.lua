-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = "0.1.0"
}

function _M.regist_default_protocol(ext)
    local motan2_protocol = require "motan.protocol.motan2"
    ext:regist_ext_protocol("motan2", function()
        return motan2_protocol:new()
    end)
end

return _M
