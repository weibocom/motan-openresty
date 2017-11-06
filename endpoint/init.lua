-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
}

function _M.regist_default_endpoint(ext)
	local motan2_endpoint = require "motan.endpoint.motan"
	ext:regist_ext_endpoint("motan2", function(url)
		return motan2_endpoint:new(url)
	end)
end

return _M
