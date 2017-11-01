-- Copyright (C) idevz (idevz.org)


local helpers = require "motan.utils"

function sprint_r( ... )
    return helpers.sprint_r(...)
end

function lprint_r( ... )
    local rs = sprint_r(...)
    print(rs)
end

function print_r( ... )
    local rs = sprint_r(...)
    ngx.say(rs)
end

local ngx = ngx
local share_motan = ngx.shared.motan
local assert = assert
local json = require 'cjson'
local singletons = require "motan.singletons"
local motan_consul = require "motan.registry.consul"
local url = require "motan.url"
local consts = require "motan.consts"
local utils = require "motan.utils"

local _to_register = function(registry_info, service_url_obj)
    local c_obj = motan_consul:new{
        host = registry_info.host,
        port = registry_info.port,
    }
    c_obj:do_register(service_url_obj)
end

local _do_heartbeat
_do_heartbeat = function(premature, heartbeat_map)
	if premature then
		return
	end
	for service_key, heartbeat_info in pairs(heartbeat_map) do
	    local c_obj = motan_consul:new{
	        host = heartbeat_info.registry_info.host,
	        port = heartbeat_info.registry_info.port,
	    }
	    c_obj:check_pass(heartbeat_info.service_url_obj)
	end
	local ok, err = ngx.timer.at(5, _do_heartbeat, heartbeat_map)
	if not ok then
		ngx.log(ngx.ERR, "failed to create the _do_register timer: ", err)
		return
	end
end

local _do_register
_do_register = function(premature, service_map)
	if premature then
		return
	end

	local heartbeat_map = {}
	local service_url_obj = {}
    for service_key, service_url_info in pairs(service_map) do
    	heartbeat_map[service_key] = {}
    	service_url_obj = url:new(service_url_info)
        local registry_key = service_url_obj.params.registry or ""
        if registry_key ~= "" then
            local registry_info = singletons.config.registry_urls[registry_key] or {}
            if registry_info ~= {} then
                _to_register(registry_info, service_url_obj)
                heartbeat_map[service_key] = {
                	registry_info = registry_info,
                	service_url_obj = service_url_obj,
                }
            end
        end
    end
    ngx.log(ngx.INFO, "Service registry: \n" .. sprint_r(heartbeat_map))
	local ok, err = ngx.timer.at(5, _do_heartbeat, heartbeat_map)
	if not ok then
		ngx.log(ngx.ERR, "failed to create the _do_register timer: ", err)
		return
	end
end

local Motan = {}

function Motan.init(path, sys_conf_files)
	local gctx = require "motan.core.gctx"
	local gctx_obj = assert(gctx:new(path, sys_conf_files), "Error to init gctx Conf.")
    local refhandler = require "motan.core.refhandler"
	singletons.config = gctx_obj
	local service_obj = refhandler:new(gctx_obj)
	local service_map_tmp = service_obj:get_section_map("service_urls")
	local service_map = {}
	local service_key = ""
	for _, info in pairs(service_map_tmp) do
        service_key = utils.build_service_key(info.group, info.params["version"],
            info.protocol, info.path)
        service_map[service_key] = info
	end
	share_motan:set(consts.MOTAN_LUA_SERVICES_SHARE_KEY, json.encode(service_map))
end

function Motan.init_worker()
	local service_map = assert(json.decode(share_motan:get(consts.MOTAN_LUA_SERVICES_SHARE_KEY))
		, "Error to get Service map at init_worker phase")
	ngx.timer.at(0, _do_register, service_map)
end

function Motan.preread()
	-- local ctx = ngx.ctx
	-- body
end

function Motan.content()
	local err_count = 1
	local byte = string.byte
	local m2codec = require "motan.protocol.m2codec"
	local handler = require "motan.server.handler"

	local sock = assert(ngx.req.socket(true))
	local m2codec_obj = m2codec:new()
	local handler_obj = handler:new{codec = m2codec_obj, sock = sock}
	local buf = ""

	while not ngx.worker.exiting() do
		local buf, err = handler_obj:invoker()
	    if not buf then
	    	err_count = err_count + 1
	        return nil, err
	    end
		if err_count > 3 then
			break
		end
		local bytes, err = sock:send(buf)
		if not bytes then
			break
		end
	end
end

return Motan