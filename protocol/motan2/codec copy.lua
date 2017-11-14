-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local header = require "motan.protocol.m2header"
local message = require "motan.protocol.message"
local utils = require "motan.utils"
local setmetatable = setmetatable
local bit = require "bit"
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    local opts = opts or {}
    local m2codec = {
        msg_type = nil, 
        proxy = opts.proxy or false, 
    }
    return setmetatable(m2codec, mt)
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
    return header:new{
        msg_type = m_type, 
        version_status = status, 
        serialize = serial, 
        request_id = request_id, 
    }
end

function _M.set_msg_type(self, msg_type)
    if msg_type and msg_type ~= consts.MOTAN_MSG_TYPE_REQUEST 
        and msg_type ~= consts.MOTAN_MSG_TYPE_RESPONSE then
        return nil, "Didn't support this msg_type" .. msg_type
    end
    self.msg_type = msg_type
end

function _M.reset_msg_type(self)
    self.msg_type = nil
end

function _M.buildRequestHeader(self, request_id)
    return self:buildHeader(consts.MOTAN_MSG_TYPE_REQUEST, false, consts.MOTAN_SERIALIZE_SIMPLE, request_id, consts.MOTAN_MSG_STATUS_NORMAL)
end

function _M.buildResponseHeader(self, request_id, msg_status)
    return self:buildHeader(consts.MOTAN_MSG_TYPE_RESPONSE, false, consts.MOTAN_SERIALIZE_SIMPLE, request_id, msg_status)
end

function _M.encode_heartbeat(self, heartbeat)
    local heartbeat_obj = header:new{
        msg_type = heartbeat.msg_type, 
        version_status = heartbeat.version_status, 
        serialize = heartbeat.serialize, 
        request_id = heartbeat.request_id, 
    }
    self:reset_msg_type()
    return heartbeat_obj:pack_header()
end

function _M.encode(self, request_id, req_obj, metadata)
    local msg_type = self.msg_type
    if msg_type and msg_type ~= consts.MOTAN_MSG_TYPE_REQUEST 
        and msg_type ~= consts.MOTAN_MSG_TYPE_RESPONSE then
        return nil, "Msg_type is empty or didn't support."
    end
    -- local bheader = self:buildRequestHeader(request_id)
    local bheader = self:buildHeader(msg_type, self.proxy, consts.MOTAN_SERIALIZE_SIMPLE, request_id, consts.MOTAN_MSG_STATUS_NORMAL)
    -- @TODO other serialization
    -- if metadata['SERIALIZATION'] ~= nil then
    bheader:set_serialize(6)
    -- end
    local msg = message:new{
        header = bheader, 
        metadata = metadata, 
        body = req_obj, 
    }
    self:reset_msg_type()
    return msg:encode()
end

function _M.decode(self, sock)
    local magic_buffer, err = sock:receive(consts.MOTAN_HEADER_MAGIC_NUM_BYTE)
    if not magic_buffer then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local magic = utils.msb_stringtonumber(magic_buffer)
    
    local msg_type_buf, err = sock:receive(consts.MOTAN_HEADER_MSG_TYPE_BYTE)
    if not msg_type_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local msg_type = utils.msb_stringtonumber(msg_type_buf)
    
    local version_status_buf, err = sock:receive(consts.MOTAN_HEADER_VERSION_STATUS_BYTE)
    if not version_status_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local version_status = utils.msb_stringtonumber(version_status_buf)
    
    local serialize_buf, err = sock:receive(consts.MOTAN_HEADER_SERIALIZE_BYTE)
    if not serialize_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local serialize = utils.msb_stringtonumber(serialize_buf)
    
    local request_id_buf, err = sock:receive(consts.MOTAN_HEADER_REQUEST_ID_BYTE)
    if not request_id_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    
    local request_id = utils.msb_stringtonumber(request_id_buf)
    -- local request_id = request_id_buf
    
    local header_obj = header:new{
        msg_type = msg_type, 
        version_status = version_status, 
        serialize = serialize, 
        request_id = request_id, 
    }
    
    if band(msg_type, 0x08) == 0x08 then
        header_obj:set_gzip(true)
    end
    
    local metadata_size_buffer, err = sock:receive(consts.MOTAN_META_SIZE_BYTE)
    if not metadata_size_buffer then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local metasize = utils.msb_stringtonumber(metadata_size_buffer)
    
    local metadata = {}
    if metasize > 0 then
        local metadata_buffer, err = sock:receive(metasize)
        if not metadata_buffer then
            return nil, err
        end
        local metadata_arr = utils.explode("\n", metadata_buffer)
        for i = 1, #metadata_arr, 2 do
            local key = metadata_arr[i]
            metadata[key] = metadata_arr[i + 1]
        end
    end
    local bodysize_buffer, err = sock:receive(consts.MOTAN_BODY_SIZE_BYTE)
    if not bodysize_buffer then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local body_size = utils.msb_stringtonumber(bodysize_buffer)
    
    local buffer, body_buffer = "", ""
    local remaining = body_size - #body_buffer
    while remaining > 0 do
        buffer, err = sock:receive(remaining)
        if not buffer then
            ngx.log(ngx.ERR, err)
            return nil, err
        end
        body_buffer = body_buffer .. buffer
        remaining = body_size - #body_buffer
    end
    local msg = message:new{
        header = header_obj, 
        metadata = metadata, 
        body = body_buffer, 
    }
    self:reset_msg_type()
    return msg
end

return _M
