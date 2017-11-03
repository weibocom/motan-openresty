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
local assert = assert
local singletons = require "motan.singletons"
local motan_consul = require "motan.registry.consul"
local consts = require "motan.consts"
local utils = require "motan.utils"

local Motan = {}

function Motan.init(sys_conf)
    local conf = require "motan.core.sysconf"
    local service = require "motan.server.service"
    local conf_obj = conf:new(sys_conf)
    singletons.config = conf_obj
    local referer_map, client_regstry = conf_obj:get_client_conf()
    singletons.referer_map = referer_map
    singletons.client_regstry = client_regstry
    local service_map_tmp, server_regstry = conf_obj:get_server_conf()
    singletons.server_regstry = server_regstry
    -- @TODO newtab()
	local service_map = {}
	local service_key = ""
	for _, info in pairs(service_map_tmp) do
        service_key = utils.build_service_key(info.group, info.params["version"],
            info.protocol, info.path)
        service_map[service_key] = service:new(info)
	end
    singletons.service_map = service_map
end

function Motan.init_worker()
	local service_map = singletons.service_map
	local server_regstry = singletons.server_regstry
	local exporter = require "motan.server.exporter"
	local exporter_obj = exporter:new(service_map, server_regstry)
	exporter_obj:export()
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
	local service_map = singletons.service_map
	local sock = assert(ngx.req.socket(true))
	local m2codec_obj = m2codec:new()
	local handler_obj = handler:new{
		codec = m2codec_obj,
		sock = sock,
		service_map = service_map
	}
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