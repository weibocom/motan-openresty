-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = "0.1.0"
}

function _M.regist_default_filter(ext)
    local metrics_filter = require "motan.filter.metrics"
    local accesslog_filter = require "motan.filter.accesslog"
    ext:regist_ext_filter("accessLog", function()
        return accesslog_filter:new()
    end)
    ext:regist_ext_filter("metrics", function()
        return metrics_filter:new()
    end)
end

return _M
