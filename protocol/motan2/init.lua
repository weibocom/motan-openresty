-- Copyright (C) idevz (idevz.org)


local ngx = ngx
local consts = require "motan.consts"
local utils = require("motan.utils")
local sprint_r = utils.sprint_r
local singletons = require "motan.singletons"
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
    _VERSION = '0.0.1'
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
    local sock = sock
    local msg, err = self.codec_obj:decode(sock)
    if err == "closed" then
        ngx.log(ngx.NOTICE, err)
        return nil, err
    end
    if not msg then
        ngx.log(ngx.ERR, "Server handler read_msg err:\n", sprint_r(err))
        return nil, err
    end
    return msg
end

function _M.buildHeader(self
    , msg_type, proxy, serialize, request_id, msg_status)
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
    return header:new{
        msg_type = m_type, 
        version_status = status, 
        serialize = serial, 
        request_id = request_id, 
    }
end

function _M.buildRequestHeader(self, request_id)
    return self:buildHeader(
        consts.MOTAN_MSG_TYPE_REQUEST
        , false
        , consts.MOTAN_SERIALIZE_SIMPLE
        , request_id, consts.MOTAN_MSG_STATUS_NORMAL
    )
end

function _M.buildResponseHeader(self, request_id, msg_status)
    return self:buildHeader(consts.MOTAN_MSG_TYPE_RESPONSE
        , false
        , consts.MOTAN_SERIALIZE_SIMPLE
        , request_id
        , msg_status
    )
end

function _M.convert_to_heartbeat_response_msg(self, req)
    local request_id = req.header.request_id
    
    local msg = message:new{
        header =  self:buildResponseHeader(
        request_id, consts.MOTAN_MSG_STATUS_NORMAL), 
        metadata = req.metadata, 
        body = nil
    }
    return self.codec_obj:encode(msg)
end

function _M.convert_to_err_response_msg(self, request_id, err)
    local request_id = request_id
    local err = err
    local header = self:buildResponseHeader(request_id
    , consts.MOTAN_MSG_STATUS_EXCEPTION)
    local metadata = {
        M_e = cjson.encode({errcode=1,errmsg=ngx.re.gsub(err, "(\n)", "", "i"),errtype=1})
    }
    local err_msg = message:new{
        header = header, 
        metadata = metadata, 
        body = nil
    }
    return self.codec_obj:encode(err_msg)
end

function _M.convert_to_response_msg(self, response, serialization)
    local response = response
    local exception = response:get_exception()
    if exception ~= nil then
        return self:convert_to_err_response_msg(
            response:get_request_id(), exception)
    end
    local serialization = serialization
    local header = self:buildResponseHeader(
        response:get_request_id(), consts.MOTAN_MSG_STATUS_NORMAL)
    local metadata = response:get_attachments()
    local body = serialization.serialize(response:get_value())
    local msg = message:new{
        header = header, 
        metadata = metadata, 
        body = body
    }
    return self.codec_obj:encode(msg)
end

-- deal with a request msg called to motan server
function _M.convert_to_request(self, msg, serialization, args_num)
    local msg = msg
    local request_id = msg.header.request_id
    local service_name = msg.metadata["M_p"]
    local method = msg.metadata["M_m"]
    local method_desc = msg.metadata["M_md"]
    local arguments = nil
    local attachment = msg.metadata
    -- @TODO check if need raw_msg
    -- local is_proxy = msg.header:is_proxy()
    -- local req_ctx = {
    --     is_proxy = is_proxy, 
    --     raw_msg = msg
    -- }
    
    if msg.header:is_gzip() then
        -- @TODO unzip
        -- msg.body = unzip()
        -- msg.header:set_gzip(false)
    end
    if args_num <= 1 then
        arguments = serialization.deserialize(msg:get_body())
    else
        arguments = serialization.deserialize_multi(msg:get_body(), args_num)
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
    local err = err
    local request = request
    local request_id = request:get_request_id()
    local attachment = request:get_attachments()
    return motan_response:new{
        request_id = request_id, 
        value = nil, 
        exception = err, 
        process_time = nil, 
        attachment = attachment
    }
end

function _M.read_reply(self, sock, serialization)
    local sock = sock
    local resp_ok, resp_err = self.codec_obj:decode(sock)

    if not resp_ok then
        ngx.log(ngx.ERR, "motan endpoint read reply err: ", resp_err)
        return nil, resp_err
    end
    
    local request_id, value, attachment, exception 
        = resp_ok.header.request_id or nil
        , serialization.deserialize(resp_ok.body) or nil
        , resp_ok.metadata or {}
        , resp_ok.metadata.M_e or nil
    return motan_response:new{
        request_id = request_id, 
        value = value, 
        exception = exception, 
        process_time = nil, 
        attachment = attachment
    }
end

function _M.convert_to_request_msg(self, request, serialization)
    local request = request
    local serialization = serialization
    local header = self:buildRequestHeader(request:get_request_id())
    local metadata = request:get_attachments()
    local body = serialization.serialize_multi(request:get_arguments())
    
    local req_msg = message:new{
        header = header, 
        metadata = metadata, 
        body = body
    }
    return self.codec_obj:encode(req_msg)
end

function _M.make_motan_request(self, url, fucname, ...)
    local url = url
    local metadata = {
        M_p = url.path, 
        M_m = fucname, 
        M_g = url.group, 
        M_pp = url.protocol, 
    }
    local request_id = utils.generate_request_id()
    local service_name = url.path
    local method_desc = nil
    local attachment = metadata
    return motan_request:new{
        request_id = request_id, 
        service_name = service_name, 
        method = fucname, 
        method_desc = method_desc, 
        arguments = {...}, 
        attachment = attachment
    }
end

return _M
