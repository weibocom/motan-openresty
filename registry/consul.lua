-- Copyright (C) idevz (idevz.org)


local pairs = pairs
local assert = assert
local setmetatable = setmetatable
local json = require 'cjson'
local consul_lib = require "resty.consul"
local url = require "motan.url"
local utils = require "motan.utils"
local consts = require "motan.consts"
local singletons = require "motan.singletons"
local consul_service = require "motan.registry.consul_service"
local escape_uri = ngx.escape_uri
local tab_concat = table.concat
local tab_insert = table.insert

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

-- @TODO ext registry
function _M.new(self, opts)
    local consul_host = opts.host or singletons.var.LOCAL_IP
    local consul_port = opts.port or consts.MOTAN_CONSUL_DEFAULT_PORT
    local consul_client = consul_lib:new{
        host = consul_host, 
        port = consul_port, 
    }
    local consul = {
        url = opts.url or {}, 
        client = consul_client, 
        subscribe_map = {}, 
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
    service:to_new{TTL = "30s"}
    return service
end

local _register_service
_register_service = function(client, url)
    local service = _build_service(url)
    local ok, res_or_err = client:put("/agent/service/register", json.encode(service))
    if not ok then
        ngx.log(ngx.ERR, "Consul _register_service error: \n" .. sprint_r(res_or_err) .. "\n")
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

local _get_sub_key
_get_sub_key = function(url)
    return url.group .. "/" .. url.path
end

local function _check_need_notify()
    -- @TODO check if is need to notify
    return true
end

local _lookup_service_update
_lookup_service_update = function(premature, registry, url, listener_map)
    if not premature then
        local ref_url_objs = registry:discover(url)
        local need_notify = _check_need_notify()
        if need_notify and not utils.is_empty(ref_url_objs) then
            for k, listener in pairs(listener_map) do
                listener:_notify(url, ref_url_objs)
            end
        end
        local ok, err = ngx.timer.at(consts.MOTAN_CONSUL_HEARTBEAT_PERIOD, _lookup_service_update, registry, url, listener_map)
        if not ok then
            ngx.log(ngx.ERR, "failed to create the _do_register timer: ", err)
            return
        end
        
    end
end

function _M.subscribe(self, url, listener)
    -- @TODO check lock
    local sub_key = _get_sub_key(url)
    local listener_map = self.subscribe_map[sub_key]
    local listener_idt = listener.url:get_identity()
    if not utils.is_empty(listener_map) then
        local lstn = listener_map[listener_idt] or {}
        if utils.is_empty(lstn) then
            listener_map[listener_idt] = listener
        end
    else
        listener_map = listener_map or {}
        listener_map[listener_idt] = listener
        self.subscribe_map[sub_key] = listener_map
        
        ngx.timer.at(0, _lookup_service_update, self, url, self.subscribe_map[sub_key])
    end
end

function _M.discover(self, url)
    local res = {}
    local group = url.group
    local service_name = assert(consts.MOTAN_CONSUL_SERVICE_MOTAN_PRE .. group, "discover at wrong server.")
    local params = "?passing&wait=600s&index=0"
    local key = "/health/service/" .. service_name .. params
    local services, ok = self.client:get(key)
    if not ok[1] then
        ngx.log(ngx.ERR, "Consul discover error: \n" .. sprint_r(ok) .. "\n")
        return false
    end
    for k, service_info in pairs(services) do
        local service = url:new{
            protocol = url.protocol, 
            host = service_info["Service"]["Address"], 
            port = service_info["Service"]["Port"], 
            path = url.path, 
            group = url.group, 
            params = url.params, 
        }
        tab_insert(res, service)
    end
    return res
end

return _M
