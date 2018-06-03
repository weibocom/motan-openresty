-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
}

function _M.regist_default_provider(ext)
    local motan_provider = require "motan.provider.motan"
    ext:regist_ext_provider("motan", function(url)
        return motan_provider:new(url)
    end)
end

return _M
