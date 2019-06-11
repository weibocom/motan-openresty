-- Copyright (C) idevz (idevz.org)

local thread = require "motan.thread"
local consts = require "motan.consts"
local utils = require "motan.utils"
local singletons = require "motan.singletons"
local setmetatable = setmetatable
local tb_insert = table.insert

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

local DEFAULT_ERROR_TIMES_TO_CLOSE_SOCK = 10
local DEFAULT_TIME_OUT = 2 * 3600 * 1000
local ERROR_TO_CLOSE_SOCK = {
    CONNECTION_CLOSED_ERR = "connection is closed by peer, ",
    THREAD_SPAWN_ERR = "failed to spawn thread, ",
    READ_MSG_FROM_PEER_ERR = "failed read msg from peer, "
}

function _M.new(self)
    local service_map = singletons.service_map
    local protocol_name = singletons.config.conf_set["MOTAN_SERVICE_PROTOCOL"] or "motan2"
    local protocol = singletons.motan_ext:get_protocol(protocol_name)
    local handler = {
        service_map = service_map,
        protocol = protocol,
        err_count = 0,
        closed_err_info = {}
    }
    return setmetatable(handler, mt)
end

function _M.error_resp(self, request_id, err)
    -- @TODO check if need convert err response together with nomal response
    -- for take more info such as serialization
    return self.protocol:convert_to_err_response_msg(request_id, err)
end

function _M.resp(self, response)
    return self.protocol:convert_to_response_msg(response)
end

-- @TODO heartbeat
function _M.heartbeat_resp(self, req)
    return self.protocol:convert_to_heartbeat_response_msg(req)
end

local get_service_method_args_num
get_service_method_args_num = function(handler, msg)
    local provider = handler.providers[msg.metadata["M_p"]]["provider"]
    local func = provider:get_service_obj(provider.url)[msg.metadata["M_m"]]
    if func ~= nil then
        return debug.getinfo(func)["nparams"] - 1
    end
    ngx.log(ngx.ERR, "get_service_method_args_num: function not found.")
    return false, "function not found."
end

local invoker
invoker = function(self, msg)
    if msg.header:is_heartbeat() then
        ngx.log(ngx.INFO, "----------------<<heartbeat>>----------------")
        return self:heartbeat_resp(msg)
    end
    if msg.metadata[consts.M2_DESERIALIZE_BODY_ERROR] ~= nil then
        return self:error_resp(msg.header.request_id, "motan deserialize concat body error.")
    end
    local service_key = msg:get_service_key()
    local service = self.service_map[service_key]
    if not utils.is_empty(service) then
        local handler = service.handler
        local args_num = get_service_method_args_num(handler, msg)
        local motan_request, err
        motan_request, err = self.protocol:convert_to_request(msg, args_num)
        if err ~= nil then
            ngx.log(
                ngx.ERR,
                "motan deserialize error, request_id:",
                msg.header.request_id,
                ";error:",
                err
            )
            return self:error_resp(msg.header.request_id, "motan deserialize error.")
        end
        local resp_obj = handler:call(motan_request)
        if resp_obj:get_exception() ~= nil then
            return self:error_resp(msg.header.request_id, resp_obj:get_exception())
        end
        return self:resp(resp_obj)
    end
    return self:error_resp(
        msg.header.request_id,
        "service didn't exist." .. service_key .. sprint_r(msg)
    )
end

local service_calling
service_calling = function(self, sock, msg)
    local buf, err = invoker(self, msg)
    if not buf then
        ngx.log(ngx.ERR, "invoker motan service error, ", err)
        return nil, err
    end
    local bytes, err = sock:send(buf)
    if not bytes then
        ngx.log(ngx.ERR, "send motan response error, ", err)
        return nil, err
    end
    return true
end

function _M.motan_server_do_request(self, sock)
    local msg, err = self.protocol:read_msg(sock)
    if err == "closed" then
        self.err_count = self.err_count + DEFAULT_ERROR_TIMES_TO_CLOSE_SOCK + 1
        tb_insert(self.closed_err_info, {ERROR_TO_CLOSE_SOCK.CONNECTION_CLOSED_ERR, err})
        return nil, ERROR_TO_CLOSE_SOCK.CONNECTION_CLOSED_ERR .. err
    end

    if err ~= nil then
        self.err_count = self.err_count + 1
        tb_insert(self.closed_err_info, {ERROR_TO_CLOSE_SOCK.READ_MSG_FROM_PEER_ERR, err})
        return nil, ERROR_TO_CLOSE_SOCK.READ_MSG_FROM_PEER_ERR .. err
    end

    do
        return service_calling(self, sock, msg)
    end
    local co, err = thread.spawn(service_calling, self, sock, msg)
    if not co then
        self.err_count = self.err_count + 1
        tb_insert(self.closed_err_info, {ERROR_TO_CLOSE_SOCK.THREAD_SPAWN_ERR, err})
        return nil, ERROR_TO_CLOSE_SOCK.THREAD_SPAWN_ERR .. err
    end

    return true
end

function _M.run(self)
    local sock = assert(ngx.req.socket(true))
    sock:settimeout(DEFAULT_TIME_OUT)
    while not ngx.worker.exiting() do
        local ok, err = self:motan_server_do_request(sock)
        if not ok then
            ngx.log(ngx.ERR, "motan_server_do_request error, ", err)
        end
        if self.err_count > DEFAULT_ERROR_TIMES_TO_CLOSE_SOCK then
            ngx.log(
                ngx.ERR,
                "failed more then ",
                DEFAULT_ERROR_TIMES_TO_CLOSE_SOCK,
                " times connection is cloesing, errors like: ",
                sprint_r(self.closed_err_info)
            )
            break
        end
    end
end

return _M
