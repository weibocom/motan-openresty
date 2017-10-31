-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local consul_lib = require "resty.consul"
local consul_service = require "motan.registry.consul_service"
local json = require 'cjson'
local null = ngx.null
local escape_uri = ngx.escape_uri
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
	local consul_host = opts.host or consts.MOTAN_CONSUL_DEFAULT_HOST
	local consul_port = opts.port or consts.MOTAN_CONSUL_DEFAULT_PORT
	local consul_client = consul_lib:new{
		host            = consul_host,
        port            = consul_port,
    }
    local consul = {
	    url = opts.url or {},
	    client = consul_client
	}
    return setmetatable(consul, mt)
end

local _build_id
_build_id = function(url)
	local id_arr = {
		url.host,
		consts.COLON_SEPARATOR,
		url.port,
		consts.MINUS_SEPARATOR,
		url.path
	}
	return assert(tab_concat(id_arr))
end

local _build_service
_build_service = function(url)
	local group = url.group or ""
	local protocol = url.protocol or ""
	local url_str = url:to_extinfo()
	local targ1 = consts.MOTAN_CONSUL_TAG_MOTAN_PROTOCOL .. protocol
	local targ2 = consts.MOTAN_CONSUL_TAG_MOTAN_URL .. escape_uri(url_str)
	local service = consul_service:new{
	    id = _build_id(url),
	    name = consts.MOTAN_CONSUL_SERVICE_MOTAN_PRE .. group,
	    tags = {targ1, targ2},
	    address = url.host or "",
	    port = url.port or 0,
	    ttl = consts.MOTAN_CONSUL_TTL,
	}
	service:to_new{TTL="30s"}
	return service
end

local _register_service
_register_service = function(client, url)
	local service = _build_service(url)
	local ok, res_or_err = client:put("/agent/service/register", json.encode(service))
	if not ok then
		print_r(res_or_err)
	end
end

function _M.do_register(self, url)
	_register_service(self.client, url)
end

function _M.check_pass(self, url)
    local key = "/agent/check/pass/service:" .. _build_id(url)
    local res, err_or_info = self.client:get(key)
    if err_or_info[1] ~= false
    	or err_or_info[2] ~= false
    	or err_or_info[3] ~= false then
    	ngx.log(ngx.ERR, "Consul check_pass error: \n" .. sprint_r(err_or_info) .. "\n")
    end
end

function _M.get(self, ...)
	return self.client:get(...)
end

function _M.do_discover(self, url)
	local group = url.group or ""
	local service_name = consts.MOTAN_CONSUL_SERVICE_MOTAN_PRE .. group
	local path = "/v1/health/service/" .. service_name
	local params = "?passing&wait=600s&index=0"
end

return _M
