-- Copyright (C) idevz (idevz.org)

local ngx = ngx
local consts = require "motan.consts"
local utils = require("motan.utils")
local motan_request = require "motan.core.request"
local motan_response = require "motan.core.response"
local codec = require "motan.protocol.motan2.codec"
local header = require "motan.protocol.motan2.header"
local message = require "motan.protocol.motan2.message"
local setmetatable = setmetatable
local bit = require "bit"
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band
local cjson = require "cjson"

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M.new(self)
    local codec_obj = codec:new()
    local motan2 = {
        codec_obj = codec_obj
    }
    return setmetatable(motan2, mt)
end

function _M.read_msg(self, sock)
    return self.codec_obj:decode(sock)
end

function _M.buildHeader(self, msg_type, proxy, serialize, request_id, msg_status)
    local m_type = 0x00
    if proxy then
        m_type = bor(m_type, 0x02)
    end
    if msg_type == consts.MOTAN_MSG_TYPE_REQUEST then
        m_type = band(m_type, 0xfe)
    else
        m_type = bor(m_type, 0x01)
    end

    local status = bor(0x08, band(msg_status, 0x07))
    local serial = bor(0x00, lshift(serialize, 3))
    return header:new {
        msg_type = m_type,
        version_status = status,
        serialize = serial,
        request_id = request_id
    }
end

function _M.buildRequestHeader(self, request_id)
    return self:buildHeader(
        consts.MOTAN_MSG_TYPE_REQUEST,
        false,
        consts.MOTAN_SERIALIZE_SIMPLE,
        request_id,
        consts.MOTAN_MSG_STATUS_NORMAL
    )
end

function _M.buildResponseHeader(self, request_id, msg_status)
    return self:buildHeader(
        consts.MOTAN_MSG_TYPE_RESPONSE,
        false,
        consts.MOTAN_SERIALIZE_SIMPLE,
        request_id,
        msg_status
    )
end

function _M.convert_to_heartbeat_response_msg(self, req)
    local msg =
        message:new {
        header = self:buildResponseHeader(req.header.request_id, consts.MOTAN_MSG_STATUS_NORMAL),
        metadata = req.metadata,
        body = nil
    }
    return self.codec_obj:encode(msg)
end

function _M.convert_to_err_response_msg(self, request_id, err)
    local err_msg =
        message:new {
        header = self:buildResponseHeader(request_id, consts.MOTAN_MSG_STATUS_EXCEPTION),
        metadata = {
            M_e = cjson.encode(
                {errcode = 1, errmsg = ngx.re.gsub(err, "(\n)", "", "i"), errtype = 1}
            )
        },
        body = nil
    }
    return self.codec_obj:encode(err_msg)
end

function _M.convert_to_response_msg(self, response, serialization)
    local exception = response:get_exception()
    if exception ~= nil then
        return self:convert_to_err_response_msg(response:get_request_id(), exception)
    end
    local msg =
        message:new {
        header = self:buildResponseHeader(response:get_request_id(), consts.MOTAN_MSG_STATUS_NORMAL),
        metadata = response:get_attachments(),
        body = serialization.serialize(response:get_value())
    }
    return self.codec_obj:encode(msg)
end

-- deal with a request msg called to motan server
function _M.convert_to_request(self, msg, serialization, args_num)
    local request_id = msg.header.request_id
    local service_name = msg.metadata["M_p"]
    local method = msg.metadata["M_m"]
    local method_desc = msg.metadata["M_md"]
    local arguments, arg_err
    local attachment = msg.metadata
    -- @TODO check if need raw_msg
    -- local is_proxy = msg.header:is_proxy()
    -- local req_ctx = {
    --     is_proxy = is_proxy,
    --     raw_msg = msg
    -- }

    if msg.header:is_gzip() then --luacheck:ignore
    -- @TODO unzip
    -- msg.body = unzip()
    -- msg.header:set_gzip(false)
    end
    if args_num <= 1 then
        arguments, arg_err = serialization.deserialize(msg:get_body())
        if arg_err ~= nil then
            ngx.log(ngx.ERR, "deserialize error, error:", arg_err)
            collectgarbage("collect")
            return nil, arg_err
        end
    else
        arguments, arg_err = serialization.deserialize_multi(msg:get_body(), args_num)
        if arg_err ~= nil then
            ngx.log(ngx.ERR, "deserialize error, error:", arg_err)
            collectgarbage("collect")
            return nil, arg_err
        end
    end

    local motan_req = {
        request_id = request_id,
        service_name = service_name,
        method = method,
        method_desc = method_desc,
        arguments = arguments,
        args_num = args_num,
        attachment = attachment
    }
    return motan_request:new(motan_req)
end

function _M.build_error_resp(self, err, request)
    local request_id = request:get_request_id()
    local attachment = request:get_attachments()
    return motan_response:new {
        request_id = request_id,
        value = nil,
        exception = err,
        process_time = nil,
        attachment = attachment
    }
end

function _M.read_reply(self, sock, serialization)
    local resp_ok, resp_err = self.codec_obj:decode(sock)
    if not resp_ok then
        ngx.log(ngx.ERR, "motan endpoint read reply err: ", resp_err)
        return nil, resp_err
    end

    local request_id, value, attachment, exception =
        resp_ok.header.request_id or nil,
        serialization.deserialize(resp_ok.body) or nil,
        resp_ok.metadata or {},
        resp_ok.metadata.M_e or nil
    return motan_response:new {
        request_id = request_id,
        value = value,
        exception = exception,
        process_time = nil,
        attachment = attachment
    }
end

function _M.convert_to_request_msg(self, request, serialization)
    local req_msg =
        message:new {
        header = self:buildRequestHeader(request:get_request_id()),
        metadata = request:get_attachments(),
        body = serialization.serialize_multi(request:get_arguments())
    }
    return self.codec_obj:encode(req_msg)
end

function _M.make_motan_request(self, url, fucname, ...)
    local metadata = {
        M_p = url.path,
        M_s = url.params["application"],
        M_m = fucname,
        M_g = url.group,
        M_pp = url.protocol
    }
    local request_id = utils.generate_request_id()
    local service_name = url.path
    local method_desc = nil
    local attachment = metadata
    return motan_request:new {
        request_id = request_id,
        service_name = service_name,
        method = fucname,
        method_desc = method_desc,
        arguments = {...},
        attachment = attachment
    }
end

return _M
