-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local header = require "motan.protocol.motan2.header"
local message = require "motan.protocol.motan2.message"
local utils = require "motan.utils"
local setmetatable = setmetatable
local tab_concat = table.concat
local bit = require "bit"
local band = bit.band

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self)
    return setmetatable({}, mt)
end

function _M.encode(self, msg)
    local msg = msg
    local buffer = msg.header:pack_header()
    local mt = {}
    local mt_index = 1
    for k, v in pairs(msg.metadata) do
        if type(v) == "table" then
            goto continue
        end
        mt[mt_index] = k .. "\n" .. v
        mt_index = mt_index + 1
        ::continue::
    end
    local mt_str = tab_concat(mt, "\n")
    buffer = buffer .. utils.msb_numbertobytes(#mt_str, 4)
    buffer = buffer .. mt_str
    local b_len, b = 0, ""
    if msg.body ~= nil then
        b_len = #msg.body
        b = msg.body
    end
    buffer = buffer .. utils.msb_numbertobytes(b_len, 4)
    buffer = buffer .. b
    
    return buffer
end

function _M.decode(self, sock)
    local sock = sock
    local magic_buffer, err = sock:receive(
        consts.MOTAN_HEADER_MAGIC_NUM_BYTE)
    if err == "closed" then
        ngx.log(ngx.NOTICE, err)
        return nil, err
    end
    if not magic_buffer then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local magic = utils.msb_stringtonumber(magic_buffer)
    
    local msg_type_buf, err = sock:receive(
        consts.MOTAN_HEADER_MSG_TYPE_BYTE)
    if not msg_type_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local msg_type = utils.msb_stringtonumber(msg_type_buf)
    
    local version_status_buf, err = sock:receive(
        consts.MOTAN_HEADER_VERSION_STATUS_BYTE)
    if not version_status_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local version_status = utils.msb_stringtonumber(version_status_buf)
    
    local serialize_buf, err = sock:receive(
        consts.MOTAN_HEADER_SERIALIZE_BYTE)
    if not serialize_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local serialize = utils.msb_stringtonumber(serialize_buf)
    
    local request_id_buf, err = sock:receive(
        consts.MOTAN_HEADER_REQUEST_ID_BYTE)
    if not request_id_buf then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    
    local request_id = utils.unpack_request_id(request_id_buf)
    
    local header_obj = header:new{
        msg_type = msg_type, 
        version_status = version_status, 
        serialize = serialize, 
        request_id = request_id, 
    }
    
    if band(msg_type, 0x08) == 0x08 then
        header_obj:set_gzip(true)
    end
    
    local metadata_size_buffer, err = sock:receive(
        consts.MOTAN_META_SIZE_BYTE)
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
    local bodysize_buffer, err = sock:receive(
        consts.MOTAN_BODY_SIZE_BYTE)
    if not bodysize_buffer then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local body_size = utils.msb_stringtonumber(bodysize_buffer)
    
    local buffer, body_buffer
    if body_size == 0 then
        buffer, body_buffer = nil, nil
    else
        buffer, body_buffer = "", ""
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
    end
    local msg = message:new{
        header = header_obj, 
        metadata = metadata, 
        body = body_buffer, 
    }
    return msg, nil
end

return _M
