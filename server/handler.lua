-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local simple = require "motan.serialize.simple"
local null = ngx.null
local escape_uri = ngx.escape_uri
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert
local json = require 'cjson'
local share_motan = ngx.shared.motan
local require = require

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local handler = {
	    _sock = opts.sock or {},
	    _codec = opts.codec or {},
	}
    return setmetatable(handler, mt)
end

function _M.error_resp(self, err)
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local req_obj = simple.serialize(err)
    local req = self._codec:encode(1121331, req_obj,{
        M_p = "com.weibo.idevz.mt.IService",
        -- M_m = "hello",
        M_m = "helloMap",
        M_g = "idevz-test-static",
        M_pp = "motan2",
        SERIALIZATION = "simple",
        })
    -- ngx.log(ngx.ERR, "--------------error_resp--------------------->" )
    return req
end

function _M.resp(self, request_id, metadata, resp_body)
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local resp_body = resp_body or ""
    local metadata = metadata or {}
    local request_id = request_id or ngx.now()
    local resp_body = simple.serialize(resp_body)
    local resp = self._codec:encode(request_id, resp_body,metadata)
    ngx.log(ngx.ERR, "--------------resp----------x----------->" .. sprint_r("") )
    return resp
end

function _M.heartbeat_resp(self, req)
    local req = req or {}
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local req_obj = simple.serialize(nil)
    local req = self._codec:encode(req.header.request_id, req_obj,{})
    return req
end

-- MOTAN_MSG_TYPE_REQUEST = 0;
-- MOTAN_MSG_TYPE_RESPONSE = 1;
function _M.invoker(self)
	local msg, err = self._codec:decode(self._sock)
    if not msg then
        return nil, err
    end
    if msg.header:is_heartbeat() then
        ngx.log(ngx.INFO, "----------------<<heartbeat>>----------------")
        return self:heartbeat_resp(msg)
    end
    local service_map = json.decode(share_motan:get(consts.MOTAN_LUA_SERVICES_SHARE_KEY))
    local group = msg.metadata["M_g"]
    local version = msg.header:get_version()
    local protocol = msg.metadata["M_pp"]
    local path = msg.metadata["M_p"]
    local service_key = utils.build_service_key(group, version, protocol, path)
    local called_service = service_map[service_key]
    
    if not utils.is_empty(called_service) then
        local resp_obj = {}
        local service_package = called_service.params[consts.MOTAN_LUA_SERVICE_PACKAGE]
        local ok, service_lib_or_error = pcall(require, service_package)
        if not ok then
            return self:error_resp(service_lib_or_error)
        end
        local service_instance = service_lib_or_error:new()
        local method = msg.metadata["M_m"]
        local req_obj = simple.deserialize(msg:get_body())
        local ok, resp_obj = pcall(service_instance[method], service_instance, req_obj)
    -- ngx.log(ngx.ERR, "--------------xxxxxaaaaaaa--------------------->" .. sprint_r(msg))
        return self:resp(msg.header.request_id, msg.metadata, resp_obj)
    end
    -- ngx.log(ngx.ERR, "Service didn't exist.------------------>\n" .. sprint_r(service_key) .. sprint_r(msg))
    return self:error_resp("Service didn't exist." .. sprint_r(service_key) .. sprint_r(msg))
end

return _M
