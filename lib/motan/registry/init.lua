-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
}

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

function _M.is_agent(url)
	local is_agent = false
	local node_type = url.params["nodeType"] or nil
	if node_type and node_type == "agent" then
		is_agent = true
	end
	return is_agent
end

return _M
