-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local simple = require "motan.serialize.simple"
local singletons = require "motan.singletons"
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self)
    local service_map = singletons.service_map
    local protocol_name = singletons.config.conf_set["MOTAN_SERVICE_PROTOCOL"] or "motan2"
    local protocol = singletons.motan_ext:get_protocol(protocol_name)
    local handler = {
        service_map = service_map,
        protocol = protocol
    }
    return setmetatable(handler, mt)
end

function _M.error_resp(self, request_id, err)
    return self.protocol:convert_to_err_response_msg(request_id, err)
end

function _M.resp(self, response, serialization)
    return self.protocol:convert_to_response_msg(response, serialization)
end

-- @TODO heartbeat
function _M.heartbeat_resp(self, req)
    local req = req or {}
    self._codec:set_msg_type(consts.MOTAN_MSG_TYPE_RESPONSE)
    local req_obj = simple.serialize(nil)
    local req = self._codec:encode(req.header.request_id, req_obj, {})
    return req
end

function _M.invoker(self, sock)
    local sock = sock
    local msg, err = self.protocol:read_msg(sock)
    if not msg then
        ngx.log(ngx.ERR, "\nRead msg from sock err:\n", sprint_r(err))
        return nil, err
    end
    if msg.header:is_heartbeat() then
        ngx.log(ngx.INFO, "----------------<<heartbeat>>----------------")
        return self:heartbeat_resp(msg)
    end
    local service_key = msg:get_service_key()
    local service = self.service_map[service_key]
    if not utils.is_empty(service) then
        local handler = service.handler
        local serialize_num = msg.header:get_serialize()
        local serialization = singletons.motan_ext:get_serialization(consts.MOTAN_SERIALIZE_ARR[serialize_num])
        local motan_request = self.protocol:convert_to_requst(msg, serialization)
        local resp_obj = handler:call(motan_request)
        return self:resp(resp_obj, serialization)
    end
    return self:error_resp(msg.header.request_id, "Service didn't exist." .. sprint_r(service_key) .. sprint_r(msg))
end

function _M.run(self)
    local sock = assert(ngx.req.socket(true))
    local err_count = 1
    local buf = ""
    
    while not ngx.worker.exiting() do
        local buf, err = self:invoker(sock)
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

return _M
