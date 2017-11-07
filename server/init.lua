-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local simple = require "motan.serialize.simple"
local m2codec = require "motan.protocol.m2codec"
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local m2codec_obj = m2codec:new()
    local handler = {
	    _sock = opts.sock or {},
	    _codec = m2codec_obj,
        service_map = opts.service_map
	}
    return setmetatable(handler, mt)
end

function _M.error_resp(self, err)
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local req_obj = simple.serialize(err)
    local req = self._codec:encode(1121331, req_obj,{})
    return req
end

function _M.resp(self, request_id, metadata, resp_body)
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local resp_body = resp_body or ""
    local metadata = metadata or {}
    local request_id = request_id or ngx.now()
    local resp_body = simple.serialize(resp_body)
    local resp = self._codec:encode(request_id, resp_body,metadata)
    return resp
end

function _M.heartbeat_resp(self, req)
    local req = req or {}
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local req_obj = simple.serialize(nil)
    local req = self._codec:encode(req.header.request_id, req_obj,{})
    return req
end

function _M.invoker(self)
	local msg, err = self._codec:decode(self._sock)
    if not msg then
        ngx.log(ngx.ERR, "\nServer handler invoker err:\n", sprint_r(err))
        return nil, err
    end
    if msg.header:is_heartbeat() then
        ngx.log(ngx.INFO, "----------------<<heartbeat>>----------------")
        return self:heartbeat_resp(msg)
    end
    local group = msg.metadata["M_g"]
    local version = msg.header:get_version()
    local protocol = msg.metadata["M_pp"]
    local path = msg.metadata["M_p"]
    local service_key = utils.build_service_key(group, version, protocol, path)
    local service = self.service_map[service_key]
    if not utils.is_empty(service) then
        local service_obj = service.service_obj
        local resp_obj = {}
        local method = msg.metadata["M_m"]
        local req_obj = simple.deserialize(msg:get_body())
        local ok, resp_obj = pcall(service_obj[method], service_obj, req_obj)
        return self:resp(msg.header.request_id, msg.metadata, resp_obj)
    end
    return self:error_resp("Service didn't exist." .. sprint_r(service_key) .. sprint_r(msg))
end

return _M
