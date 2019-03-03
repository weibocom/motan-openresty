-- Copyright (C) idevz (idevz.org)

local singletons = require "motan.singletons"
local utils = require "motan.utils"
local sprint_r = utils.sprint_r

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M.new(self)
    local service_protocol = singletons.sys_conf.conf_set["MOTAN_SERVICE_PROTOCOL"] or "motan2"
    local protocol_obj = singletons.motan_ext:get_protocol(service_protocol)
    local ctx = ngx.ctx
    local motan_ctx = ctx.motan_ctx or {}
    motan_ctx.protocol = protocol_obj
    local preread = {
        protocol_obj = protocol_obj
    }
    return setmetatable(preread, mt)
end

function _M.preread_msg(self)
    local ctx = ngx.ctx
    local motan_ctx = ctx.motan_ctx
    local msg, err = self.protocol_obj:read_msg()
    if not msg then
        ngx.log(ngx.ERR, "\nPreread msg from sock err:\n", sprint_r(err))
        return nil, err
    end
    local service_map = singletons.service_map

    local service_key = msg:get_service_key()
    local service = service_map[service_key]
    if utils.is_empty(service) then
        motan_ctx.can_serve = false
        local err_msg = "Can't find service througt service key:" .. service_key
        ngx.log(ngx.ERR, err_msg)
        return nil, err_msg
    end
    motan_ctx.req_msg = msg
    return true
end

return _M
