-- Copyright (C) idevz (idevz.org)


local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new()
	local ext = {
		endpoint_fctrs = {},
		registry_fctrs = {},
		registries = {},
	}
	return setmetatable(ext, mt)
end

local _new_index
_new_index = function(self, key, name, func)
	if type(func) ~= "function" then
		local err_msg = "None function for ext " .. key.. ": " .. name
		ngx.log(ngx.ERR, err_msg)
		return nil, err_msg
	end
	self[key][name] = func
	return true, nil
end

--+--------------------------------------------------------------------------------+--
function _M.regist_ext_endpoint(self, name, func)
	return _new_index(self, "endpoint_fctrs", name, func)
end

function _M.get_endpoint(self, url)
	local key = url.protocol
	local new_endpoint = self.endpoint_fctrs[url.protocol]
	if new_endpoint ~= nil then
		return new_endpoint(url)
	end
	ngx.log(ngx.ERR, "Didn't have a endpoint: " .. key)
end


--+--------------------------------------------------------------------------------+--
function _M.regist_ext_registry(self, name, func)
	return _new_index(self, "registry_fctrs", name, func)
end

function _M.get_registry(self, url)
	local key = url:get_identity()
	local registries_cache = self.registries[key] or {}
	if registries_cache[self.registries[key]] ~= nil then
		return registries_cache
	else
		local registry = self.registry_fctrs[url.protocol]
		if registry ~= nil then
			registry_obj = registry(url)
			self.registries[key] = registry_obj
			return registry_obj
		else
			ngx.log(ngx.ERR, "Didn't have a registry: " .. key)
			return nil
		end
	end
end

return _M
