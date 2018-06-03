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
local timer = require "resty.timer"
local escape_uri = ngx.escape_uri
local tab_concat = table.concat
local tab_insert = table.insert
local sprint_r = utils.sprint_r

local DEFAULT_TIMEOUT = 60*1000 -- 60s default timeout
local DEFAULT_HEART_INTERVAL  = 5

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
    local ok, res_or_err = client:put("/agent/service/register"
    , json.encode(service))
    if not ok then
        ngx.log(ngx.ERR
        , "Consul _register_service error:" 
        , sprint_r(res_or_err))
        return nil, res_or_err
    end
    return true
end

local _check_pass
_check_pass = function(client, url)
    local key = "/agent/check/pass/service:" .. _build_id(url)
    local res, err_or_info = client:put(key)
    if err_or_info ~= nil then
        ngx.log(ngx.ERR
        , "Consul check_pass error:" 
        , sprint_r(err_or_info))
        return nil, err_or_info
    end
    return true
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

-- @TODO ext registry
function _M:new(url)
    local consul_host = url.host or singletons.var.LOCAL_IP
    local consul_port = url.port or consts.MOTAN_CONSUL_DEFAULT_PORT
    local consul_client = consul_lib:new{
        host = consul_host, 
        port = consul_port, 
    }

    local timeout = url.timeout or DEFAULT_TIMEOUT
    local heart_interval = url.heart_interval or DEFAULT_HEART_INTERVAL

    local consul = {
        url = url,
        client = consul_client, 
        subscribe_map = {}, 
        timeout = timeout,
        heart_interval = heart_interval,
    }
    return setmetatable(consul, mt)
end

function _M:get_name()
    return "consulxRegistry"
end

function _M:get_url()
    return self.url
end

function _M:set_url(url)
    self.url = url
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
_lookup_service_update = function(self, url)
    local sub_key = _get_sub_key(url)
    local listener_map = self.subscribe_map[sub_key]
    local ref_url_objs = self:discover(url)
    local need_notify = _check_need_notify()
    if need_notify and not utils.is_empty(ref_url_objs) then
        for k, listener in pairs(listener_map) do
            listener:_notify(self.url, ref_url_objs)
        end
    end
end

function _M:subscribe(url, listener)
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

        local notify_timer = timer:new()
        notify_timer:tick(
            notify_timer.NO_RES, self.heart_interval, 
            _lookup_service_update, self, url)
    end
end

function _M:unsubscribe(url, listener)
end

function _M:discover(url)
    local res = {}
    local group = url.group
    local service_name = assert(consts.MOTAN_CONSUL_SERVICE_MOTAN_PRE 
    .. group, "discover at wrong server.")
    local params = "?passing&wait=600s&index=0"
    local key = "/health/service/" .. service_name .. params
    local services, ok = self.client:get(key)
    if not ok[1] then
        ngx.log(ngx.ERR, "Consul discover error: \n", sprint_r(ok))
        return nil, sprint_r(ok)
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

function _M:subscribe_command(url, listener)
end

function _M:unsubscribe_command(url, listener)
end

function _M:discover_command(url)
end

local _get_consul_obj
_get_consul_obj = function(registry_info)
    return motan_consul:new{
        host = registry_info.host, 
        port = registry_info.port, 
    }
end

local _do_heartbeat
_do_heartbeat = function(client, service_url_obj_arr)
    for _, service_url_obj in ipairs(service_url_obj_arr) do
        local ok, err = _check_pass(client, service_url_obj)
        if err ~= nil then
            ngx.log(ngx.ERR, "Consul heartbeat Error:" , 
            err, service_url_obj:get_identity())
        end
    end
end

function _M:heartbeat(service_url_obj_arr)
    local heartbeat_timer = timer:new(true)
    heartbeat_timer:tick(
        heartbeat_timer.NO_RES, self.heart_interval, 
        _do_heartbeat, self.client, service_url_obj_arr)
end

function _M:register(service_url)
    if service_url.group == ""
    or service_url.path  == ""
    or service_url.host  == ""
    or service_url.port  == 0 then
        ngx.log(ngx.ERR, 
        "Register Fail, invalid url:"
        , service_url:get_identity())
        return
    end
    if ngx.worker.id() == 0 then
        ngx.timer.at(0, function(premature, client, service_url)
            if not premature then
                local service_url_obj = service_url
                local ok, err = _register_service(client, service_url_obj)
                if err ~= nil then
                    ngx.log(ngx.ERR, "Consul register Error:" , 
                    err, service_url_obj:get_identity())
                    return false
                end
                ngx.log(ngx.INFO, "Service registry: \n", service_url_obj:get_identity())
            end
        end, self.client, service_url)
    end
end

function _M:unregister(server_url)
end

function _M:available(server_url)
end

function _M:unavailable(server_url)
end

function _M:get_registered_services()
end

function _M:start_snapshot(conf)
end

return _M
