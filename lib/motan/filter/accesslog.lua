-- Copyright (C) idevz (idevz.org)

local setmetatable = setmetatable
local consts = require "motan.consts"
local utils = require "motan.utils"

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}
local LOG_SEPARATOR = consts.COMMA_SEPARATOR

function _M:new(self, url)
    local accessLog = {
        name = "accessLog",
        url = url or {},
        next = {}
    }
    return setmetatable(accessLog, mt)
end

function _M.get_index(self)
    return 1
end

function _M.get_name(self)
    return self.name
end

function _M.new_filter(self, url)
    if not utils.is_empty(url) then
        LOG_SEPARATOR = url.params["logSeparator"] or LOG_SEPARATOR
    end
    return self:new(url)
end

local function _do_access_log(filter_name, role, remote_address, start_time, request, response)
    utils.access_log(
        filter_name, LOG_SEPARATOR,
        role, LOG_SEPARATOR,
        response.request_id, LOG_SEPARATOR,
        request.service_name, LOG_SEPARATOR,
        request.method, LOG_SEPARATOR,
        remote_address, LOG_SEPARATOR,
        request:get_method_desc(), LOG_SEPARATOR,
        request:get_request_body_size(), LOG_SEPARATOR,
        #response:get_value(), LOG_SEPARATOR,
        response:get_process_time(), LOG_SEPARATOR,
        math.floor(((ngx.now() - start_time) * 100) + 0.5) * 0.01, LOG_SEPARATOR,
        response.exception == nil, LOG_SEPARATOR,
        response.exception
    )
end

function _M.filter(self, caller, req)
    local start_time = ngx.now()
    local resp = self:get_next():filter(caller, req)
    local role, address
    if caller.url.params.provider ~= nil then
        role = "mor-server"
        address = ngx.var.remote_addr
    else
        role = "mor-client"
        address = caller.url.host .. ":" .. caller.url.port
    end
    _do_access_log(self.name, role, address, start_time, req, resp)
    return resp
end

function _M.has_next(self)
    return not utils.is_empty(self.next)
end

function _M.set_next(self, next_filter)
    self.next = next_filter
end

function _M.get_next(self)
    return self.next
end

function _M.get_type(self)
    return consts.MOTAN_FILTER_TYPE_ENDPOINT
end

function _M.is_available(self)
    if self.url.port == 8005 then
        return false
    end
    return true
end

return _M
