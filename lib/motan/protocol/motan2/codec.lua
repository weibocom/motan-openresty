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
    _VERSION = "0.1.0"
}

local mtb = {__index = _M}

function _M.new(self)
    return setmetatable({}, mtb)
end

function _M.encode(self, msg)
    local buffer = msg.header:pack_header()
    local mt = {}
    local mt_index = 1
    for k, v in pairs(msg.metadata) do
        if type(v) ~= "table" then
            mt[mt_index] = k .. "\n" .. v
            mt_index = mt_index + 1
        end
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
    local magic_buffer, mgc_err = sock:receive(consts.MOTAN_HEADER_MAGIC_NUM_BYTE)
    if mgc_err == "closed" then
        ngx.log(ngx.NOTICE, mgc_err)
        return nil, mgc_err
    end
    if not magic_buffer then
        ngx.log(ngx.ERR, mgc_err)
        return nil, mgc_err
    end
    local magic = utils.msb_stringtonumber(magic_buffer)

    local msg_type_buf, typ_err = sock:receive(consts.MOTAN_HEADER_MSG_TYPE_BYTE)
    if not msg_type_buf then
        ngx.log(ngx.ERR, typ_err)
        return nil, typ_err
    end
    local msg_type = utils.msb_stringtonumber(msg_type_buf)

    local version_status_buf, vs_err = sock:receive(consts.MOTAN_HEADER_VERSION_STATUS_BYTE)
    if not version_status_buf then
        ngx.log(ngx.ERR, vs_err)
        return nil, vs_err
    end
    local version_status = utils.msb_stringtonumber(version_status_buf)

    local serialize_buf, s_err = sock:receive(consts.MOTAN_HEADER_SERIALIZE_BYTE)
    if not serialize_buf then
        ngx.log(ngx.ERR, s_err)
        return nil, s_err
    end
    local serialize = utils.msb_stringtonumber(serialize_buf)

    local request_id_buf, rid_err = sock:receive(consts.MOTAN_HEADER_REQUEST_ID_BYTE)
    if not request_id_buf then
        ngx.log(ngx.ERR, rid_err)
        return nil, rid_err
    end

    local request_id = utils.unpack_request_id(request_id_buf)

    local header_obj =
        header:new {
        magic = magic,
        msg_type = msg_type,
        version_status = version_status,
        serialize = serialize,
        request_id = request_id
    }

    if band(msg_type, 0x08) == 0x08 then
        header_obj:set_gzip(true)
    end

    local metadata_size_buffer, m_err = sock:receive(consts.MOTAN_META_SIZE_BYTE)
    if not metadata_size_buffer then
        ngx.log(ngx.ERR, m_err)
        return nil, m_err
    end
    local metasize = utils.msb_stringtonumber(metadata_size_buffer)

    local metadata = {}
    if metasize > 0 then
        local metadata_buffer, mb_err = sock:receive(metasize)
        if not metadata_buffer then
            return nil, mb_err
        end
        local metadata_arr = utils.explode("\n", metadata_buffer)
        for i = 1, #metadata_arr, 2 do
            local key = metadata_arr[i]
            metadata[key] = metadata_arr[i + 1]
        end
    end
    local bodysize_buffer, b_err = sock:receive(consts.MOTAN_BODY_SIZE_BYTE)
    if not bodysize_buffer then
        ngx.log(ngx.ERR, b_err)
        return nil, b_err
    end
    local body_size = utils.msb_stringtonumber(bodysize_buffer)

    local buffer, body_buffer, bf_err
    if body_size > 0 then
        body_buffer = ""
        local remaining = body_size - #body_buffer
        while remaining > 0 do
            buffer, bf_err = sock:receive(remaining)
            if not buffer then
                ngx.log(ngx.ERR, bf_err)
                return nil, bf_err
            end
            body_buffer = body_buffer .. buffer
            remaining = body_size - #body_buffer
        end
    end
    local msg =
        message:new {
        header = header_obj,
        metadata = metadata,
        body = body_buffer
    }
    return msg, nil
end

return _M
