-- Copyright (C) idevz (idevz.org)

local _M = {
    _VERSION = "0.1.0"
}

function _M.regist_default_serializations(ext)
    local simple_serialize = require "motan.serialize.simple_native"
    --local simple_serialize = require "motan.serialize.simplex"
    -- local simple_serialize = require "motan.serialize.simple"
    ext:regist_ext_serialization(
        "simple",
        function()
            return simple_serialize
        end
    )
end

return _M
