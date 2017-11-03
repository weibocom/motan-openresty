-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local setmetatable = setmetatable
local type = type
local str_sub = string.sub

local _M = {
    _VERSION = '0.0.1'
}

function _M.serialize(params)
    local buffer = ""
    local p_type = type(params)
    if p_type == "table" then
        buffer = utils.msb_numbertobytes(2, consts.MOTAN_SIMPLE_TYPE_BYTE)
        local btemp = ""
        local btemp_len = 0
        for k,v in pairs(params) do
            if type(v) == "table" then
                goto continue
            end
            btemp = btemp 
                    .. utils.msb_numbertobytes(#k, consts.MOTAN_DATA_PACK_INT32_BYTE) .. k 
                    .. utils.msb_numbertobytes(#v, consts.MOTAN_DATA_PACK_INT32_BYTE) .. v
            btemp_len = btemp_len + #k + #v + 8
            ::continue::
        end
        buffer = buffer .. utils.msb_numbertobytes(btemp_len, consts.MOTAN_DATA_PACK_INT32_BYTE) .. btemp
    elseif p_type == "string" then
        buffer = utils.msb_numbertobytes(1, consts.MOTAN_SIMPLE_TYPE_BYTE) 
                 .. utils.msb_numbertobytes(#params, consts.MOTAN_DATA_PACK_INT32_BYTE) .. params
    elseif p_type == nil then
        buffer = utils.msb_numbertobytes(0, consts.MOTAN_SIMPLE_TYPE_BYTE)
    end
    return buffer
end

function _M.deserialize(data)
    local obj = {}
    if data == null then
        return obj
    end
    local pos = 1
    local body_len = 0
    local buf_type = utils.msb_stringtonumber(str_sub(data, pos, consts.MOTAN_SIMPLE_TYPE_BYTE))
    pos = pos + consts.MOTAN_SIMPLE_TYPE_BYTE
    if buf_type == 0 then
        obj = null
    elseif buf_type == 1 then
        body_len = utils.msb_stringtonumber(str_sub(data, pos, pos + consts.MOTAN_DATA_PACK_INT32_BYTE  - 1))
        pos = pos + consts.MOTAN_DATA_PACK_INT32_BYTE
        obj = str_sub(data, pos)
    elseif buf_type == 2 then
        body_len = utils.msb_stringtonumber(str_sub(data, pos, pos + consts.MOTAN_DATA_PACK_INT32_BYTE))
        pos = pos + consts.MOTAN_DATA_PACK_INT32_BYTE
        local map_buf = str_sub(data, pos, pos + body_len - 1)
        local map_pos = 1
        local key_len = utils.msb_stringtonumber(str_sub(map_buf, map_pos, consts.MOTAN_DATA_PACK_INT32_BYTE))
        map_pos = map_pos + consts.MOTAN_DATA_PACK_INT32_BYTE
        local key = str_sub(map_buf, map_pos, map_pos + key_len - 1)
        map_pos = map_pos + key_len
        local value = ""
        local value_len = 0
        while key ~= "" do
            value_len = utils.msb_stringtonumber(str_sub(map_buf, map_pos, map_pos + consts.MOTAN_DATA_PACK_INT32_BYTE - 1))
            map_pos = map_pos + consts.MOTAN_DATA_PACK_INT32_BYTE
            value = str_sub(map_buf, map_pos, map_pos + value_len - 1)
            map_pos = map_pos + value_len
            if value ~= false then
                obj[key] = value
            end
            if map_pos == body_len then
                break
            end
            key_len = utils.msb_stringtonumber(str_sub(map_buf, map_pos, map_pos + consts.MOTAN_DATA_PACK_INT32_BYTE - 1))
            map_pos = map_pos + consts.MOTAN_DATA_PACK_INT32_BYTE
            key = str_sub(map_buf, map_pos, map_pos + key_len - 1)
            map_pos = map_pos + key_len
        end
    else
        ngx.log(ngx.ERR, "Fail to Decode response body, got a no support type!")
    end
    return obj
end

return _M
