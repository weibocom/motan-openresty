-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
}

-- @TODO direct registry
function _M.regist_default_registry(ext)
	local consul_registry = require "motan.registry.consul"
	ext:regist_ext_registry("consul", function(url)
		return consul_registry:new(url)
	end)
	local direct_registry = require "motan.registry.direct"
	ext:regist_ext_registry("direct", function(url)
		return direct_registry:new(url)
	end)
end

return _M
