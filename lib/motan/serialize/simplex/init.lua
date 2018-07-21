-- Copyright (C) idevz (idevz.org)

local type = type
local utils = require "motan.utils"
local consts = require "motan.consts"
local buf_lib = require "motan.serialize.simplex.buf"
local floor = require "math".floor

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function(narr, nrec) --luacheck:ignore
        return {nil, [narr] = 0}
    end
end

local _M = {
    _VERSION = "0.0.1"
}

local motan_table_type
motan_table_type = function(v)
    local err, data_type = nil
    local orgin_len = #v
    local add_one_len = 0
    local v_type = type(v)
    local v_type_number = {byte = false, int = false}
    v["check_if_is_a_array_or_a_hash"] = false
    for k, value in pairs(v) do
        add_one_len = add_one_len + 1
        if k ~= "check_if_is_a_array_or_a_hash" then
            v_type = type(value)
            if v_type == "number" then
                if value >= 0 and value <= 0xff then
                    v_type_number.byte = true
                else
                    v_type_number.int = true
                end
            end
        end
    end
    if orgin_len == 0 and add_one_len > 1 then
        if v_type == "string" then
            data_type = consts.DTYPE_STRING_MAP
        else
            data_type = consts.DTYPE_MAP
        end
    elseif orgin_len == add_one_len - 1 then
        if v_type == "number" and v_type_number.byte == true and v_type_number.int == false then
            data_type = consts.DTYPE_BYTE_ARRAY
        elseif v_type == "string" then
            data_type = consts.DTYPE_STRING_ARRAY
        else
            data_type = consts.DTYPE_ARRAY
        end
    else
        data_type = nil
        err = "UnSupport table type."
    end
    v["check_if_is_a_array_or_a_hash"] = nil
    return data_type, err
end

local motan_number_type
motan_number_type = function(n)
    local err, data_type = nil
    if floor(n) ~= n then
        return consts.DTYPE_FLOAT64, nil
    end
    if n >= 0 then
        if n <= 0xff then
            data_type = consts.DTYPE_BYTE
        elseif n <= 0xffff then
            data_type = consts.DTYPE_INT16
        elseif n <= 4294967295.0 then
            data_type = consts.DTYPE_INT32
        else
            data_type = consts.DTYPE_INT64
        end
    else -- @TODO n < 0
        if n >= -0x8000 then
            data_type = consts.DTYPE_INT16
        elseif n >= -0x80000000 then
            data_type = consts.DTYPE_INT32
        else
            data_type = consts.DTYPE_INT64
        end
    end
    return data_type, err
end

local encode_string_no_tag
encode_string_no_tag = function(s, buf)
    buf:write_uint32(#s)
    buf:write({string.byte(s, 1, -1)})
end

local encode_string
encode_string = function(s, buf)
    buf:write_byte(consts.DTYPE_STRING)
    encode_string_no_tag(s, buf)
end

local encode_bool
encode_bool = function(bool_params, buf)
    buf:write_byte(consts.DTYPE_BOOL)
    if bool_params then
        buf:write_byte(1)
    else
        buf:write_byte(0)
    end
end

local encode_byte
encode_byte = function(params, buf)
    buf:write_byte(consts.DTYPE_BYTE)
    buf:write_byte(params)
end

local encode_int16
encode_int16 = function(params, buf)
    buf:write_byte(consts.DTYPE_INT16)
    buf:write_uint16(params)
end

local encode_int32
encode_int32 = function(params, buf)
    buf:write_byte(consts.DTYPE_INT32)
    buf:write_zigzag32(params)
end

local encode_int64
encode_int64 = function(params, buf)
    buf:write_byte(consts.DTYPE_INT64)
    buf:write_zigzag64(params)
end

local encode_float64
encode_float64 = function(params, buf)
    buf:write_byte(consts.DTYPE_FLOAT64)
    buf:write_uint64(params)
end

local encode_string_array
encode_string_array = function(string_array, buf)
    buf:write_byte(consts.DTYPE_STRING_ARRAY)
    local pos = buf:get_wpos()
    buf:set_wpos(pos + 4)
    for _, v in ipairs(string_array) do
        encode_string_no_tag(v, buf)
    end
    local npos = buf:get_wpos()
    buf:set_wpos(pos)
    buf:insert_uint(npos - pos - 4)
    buf:set_wpos(npos)
end

local encode_bytes
encode_bytes = function(bytes_array, buf)
    buf:write_byte(consts.DTYPE_BYTE_ARRAY)
    buf:write_uint32(#bytes_array)
    buf:write(bytes_array)
end

local serialize_buf
local encode_array
encode_array = function(params, buf)
    buf:write_byte(consts.DTYPE_ARRAY)
    local pos = buf:get_wpos()
    buf:set_wpos(pos + 4)
    local err
    for _, v in ipairs(params) do
        err = serialize_buf(v, buf)
        if err ~= nil then
            return err
        end
    end
    local npos = buf:get_wpos()
    buf:set_wpos(pos)
    buf:insert_uint(npos - pos - 4)
    buf:set_wpos(npos)
    return nil
end

local encode_string_map
encode_string_map = function(params, buf)
    buf:write_byte(consts.DTYPE_STRING_MAP)
    local pos = buf:get_wpos()
    buf:set_wpos(pos + 4)
    for k, v in pairs(params) do
        if type(v) ~= "table" then
            if type(v) == "boolean" then
                v = tostring(v)
            end
            encode_string_no_tag(k, buf)
            encode_string_no_tag(v, buf)
        end
    end
    local npos = buf:get_wpos()
    buf:set_wpos(pos)
    buf:insert_uint(npos - pos - 4)
    buf:set_wpos(npos)
end

local encode_map
encode_map = function(params, buf)
    buf:write_byte(consts.DTYPE_MAP)
    local pos = buf:get_wpos()
    buf:set_wpos(pos + 4)
    local err = nil
    for k, v in pairs(params) do
        err = serialize_buf(k, buf)
        if err ~= nil then
            return err
        end
        err = serialize_buf(v, buf)
        if err ~= nil then
            return err
        end
    end
    local npos = buf:get_wpos()
    buf:set_wpos(pos)
    buf:insert_uint(npos - pos - 4)
    buf:set_wpos(npos)
    return err
end

serialize_buf = function(params, buf)
    local p_type = type(params)
    if p_type == "string" then
        encode_string(params, buf)
    elseif p_type == "boolean" then
        encode_bool(params, buf)
    elseif p_type == "number" then
        local p_type_c, p_type_err = motan_number_type(params)
        if not p_type_err then
            if p_type_c == consts.DTYPE_BYTE then
                encode_byte(params, buf)
            elseif p_type_c == consts.DTYPE_INT16 then
                encode_int16(params, buf)
            elseif p_type_c == consts.DTYPE_INT32 then
                encode_int32(params, buf)
            elseif p_type_c == consts.DTYPE_INT64 then
                encode_int64(params, buf)
            elseif p_type_c == consts.DTYPE_FLOAT64 then -- @TODO encode_float32
                encode_float64(params, buf)
            end
        else
            return nil, p_type_err
        end
    elseif p_type == "table" then
        local p_type_c, p_type_err = motan_table_type(params)
        if not p_type_err then
            if p_type_c == consts.DTYPE_STRING_ARRAY then
                encode_string_array(params, buf)
            elseif p_type_c == consts.DTYPE_BYTE_ARRAY then
                encode_bytes(params, buf)
            elseif p_type_c == consts.DTYPE_ARRAY then
                encode_array(params, buf)
            elseif p_type_c == consts.DTYPE_STRING_MAP then
                encode_string_map(params, buf)
            elseif p_type_c == consts.DTYPE_MAP then
                encode_map(params, buf)
            end
        else
            return nil, p_type_err
        end
    elseif p_type == "nil" or params == ngx.null then
        buf:write_byte(consts.DTYPE_NULL)
    end
    return nil
end

function _M.serialize(params)
    local buf = buf_lib:new_bytes_buff(consts.DEFAULT_BUFFER_SIZE)
    local err = serialize_buf(params, buf)
    return string.char(unpack(buf.byte_arr_buf)), err
end

function _M.serialize_multi(params)
    if #params == 0 then
        return nil, nil
    end
    local err
    local buf = buf_lib:new_bytes_buff(consts.DEFAULT_BUFFER_SIZE)
    for _, v in ipairs(params) do
        if type(v) == "table" and utils.is_empty(v) then
            v = nil
        end
        err = serialize_buf(v, buf)
        if err ~= nil then
            return nil, err
        end
    end
    return string.char(unpack(buf.byte_arr_buf)), err
end

-- consts.MOTAN_DATA_PACK_INT32_BYTE - 1
-- obj = str_sub(data, pos) not any body_len
local decode_string
decode_string = function(buf)
    local size, read_i_err = buf:read_int()
    if read_i_err ~= nil then
        return "", read_i_err
    end
    local str_byte_array, bf_err = buf:next(size)
    if bf_err ~= nil then
        return "", "ErrNotEnough"
    end
    -- if v ~= nil then
    -- v = str -- @TODO check this reference value
    -- end
    return string.char(unpack(str_byte_array)), nil
end

local decode_string_map
decode_string_map = function(buf)
    local total, err = buf:read_int()
    if err ~= nil then
        return nil, err
    end
    if total <= 0 then
        return nil, nil
    end
    local m = new_tab(32, 0)
    local pos = buf:get_rpos()
    local k, tv
    while (buf:get_rpos() - pos < total) do
        k, err = decode_string(buf, nil)
        if err ~= nil then
            return nil, err
        end
        if (buf:get_rpos() - pos) > total then
            return nil, "ErrWrongSize"
        end
        tv, err = decode_string(buf, nil)
        if err ~= nil then
            return nil, err
        end
        if (buf:get_rpos() - pos) > total then
            return nil, "ErrWrongSize"
        end
        m[k] = tv
    end
    return m, nil
end

local decode_bytes_array
decode_bytes_array = function(buf)
    local size, err = buf:read_int()
    if err ~= nil then
        return nil, err
    end
    local b, bf_err = buf:next(size)
    if bf_err ~= nil then
        return nil, "ErrNotEnough"
    end
    return b, nil
end

local decode_string_array
decode_string_array = function(buf)
    local total, err = buf:read_int()
    if err ~= nil then
        return nil, err
    end
    if total <= 0 then
        return nil, nil
    end
    local a = new_tab(32, 0)
    local pos = buf:get_rpos()
    local tv
    while (buf:get_rpos() - pos < total) do
        tv, err = decode_string(buf, nil)
        if err ~= nil then
            return nil, err
        end
        table.insert(a, tv)
    end
    if buf:get_rpos() - pos ~= total then
        return nil, "ErrWrongSize"
    end
    return a, nil
end

local decode_bool
decode_bool = function(buf)
    local b, err = buf:read_byte()
    if err ~= nil then
        return false, err
    end
    local ret = false
    if b == 1 then
        ret = true
    end
    return ret, nil
end

local decode_byte
decode_byte = function(buf)
    local b, err = buf:read_byte()
    if err ~= nil then
        return 0, err
    end
    return b, nil
end

local decode_int16
decode_int16 = function(buf)
    local i, err = buf:read_uint16()
    if err ~= nil then
        return 0, err
    end
    return i, nil
end

local decode_int32
decode_int32 = function(buf)
    local i, err = buf:read_zigzag32()
    if err ~= nil then
        return 0, err
    end
    return i, nil
end

local decode_int64
decode_int64 = function(buf)
    local i, err = buf:read_zigzag64()
    if err ~= nil then
        return 0, err
    end
    return i, nil
end

local decode_float32
decode_float32 = function(buf)
    local i, err = buf:read_uint32()
    if err ~= nil then
        return 0, err
    end
    -- f := math.Float32frombits(i)
    return i, nil
end

local decode_float64
decode_float64 = function(buf)
    local i, err = buf:read_uint64()
    if err ~= nil then
        return 0, err
    end
    -- f := math.Float64frombits(i)
    return i, nil
end

local deserialize_buf
local decode_map
decode_map = function(buf)
    local total, err = buf:read_int()
    if err ~= nil then
        return nil, err
    end
    if total <= 0 then
        return nil, nil
    end
    local m = new_tab(32, 0)
    local k, tv
    local pos = buf:get_rpos()
    while (buf:get_rpos() - pos < total) do
        k, err = deserialize_buf(buf, nil)
        if err ~= nil then
            return nil, err
        end
        if buf:get_rpos() - pos > total then
            return nil, "ErrWrongSize"
        end
        tv, err = deserialize_buf(buf, nil)
        if err ~= nil then
            return nil, err
        end
        if buf:get_rpos() - pos > total then
            return nil, "ErrWrongSize"
        end
        m[k] = tv
    end
    return m, nil
end

local decode_array
decode_array = function(buf)
    local total, err = buf:read_int()
    if err ~= nil then
        return nil, err
    end
    if total <= 0 then
        return nil, nil
    end
    local a = new_tab(32, 0)
    local pos = buf:get_rpos()
    local tv
    while (buf:get_rpos() - pos < total) do
        tv, err = deserialize_buf(buf, nil)
        if err ~= nil then
            return nil, err
        end
        table.insert(a, tv)
    end
    if buf:get_rpos() - pos ~= total then
        return nil, "ErrWrongSize"
    end
    return a, nil
end
--

--[[
// serialize type
const (
	sNull = iota
	sString
	sStringMap
	sByteArray
	sStringArray
	sBool
	sByte
	sInt16
	sInt32
	sInt64
	sFloat32
	sFloat64

	// [string]interface{}
	sMap   = 20
	sArray = 21
)

DTYPE_NULL = 0
DTYPE_STRING = 1
DTYPE_STRING_MAP = 2
DTYPE_BYTE_ARRAY = 3
DTYPE_STRING_ARRAY = 4
DTYPE_BOOL = 5
DTYPE_BYTE = 6
DTYPE_INT16 = 7
DTYPE_INT32 = 8
DTYPE_INT64 = 9
DTYPE_FLOAT32 = 10
DTYPE_FLOAT64 = 11

DTYPE_MAP = 20
DTYPE_ARRAY = 21
]] deserialize_buf = function(
    buf)
    local buf_type, err = buf:read_byte()
    if err ~= nil then
        return nil, err
    end
    -- ngx.log
    if buf_type == consts.DTYPE_NULL then
        return nil, nil
    elseif buf_type == consts.DTYPE_STRING then
        return decode_string(buf)
    elseif buf_type == consts.DTYPE_STRING_MAP then
        return decode_string_map(buf)
    elseif buf_type == consts.DTYPE_BYTE_ARRAY then
        return decode_bytes_array(buf)
    elseif buf_type == consts.DTYPE_STRING_ARRAY then
        return decode_string_array(buf)
    elseif buf_type == consts.DTYPE_BOOL then
        return decode_bool(buf)
    elseif buf_type == consts.DTYPE_BYTE then
        return decode_byte(buf)
    elseif buf_type == consts.DTYPE_INT16 then
        return decode_int16(buf)
    elseif buf_type == consts.DTYPE_INT32 then
        return decode_int32(buf)
    elseif buf_type == consts.DTYPE_INT64 then
        return decode_int64(buf)
    elseif buf_type == consts.DTYPE_FLOAT32 then
        return decode_float32(buf)
    elseif buf_type == consts.DTYPE_FLOAT64 then
        return decode_float64(buf)
    elseif buf_type == consts.DTYPE_MAP then
        return decode_map(buf)
    elseif buf_type == consts.DTYPE_ARRAY then
        return decode_array(buf)
    end
    ngx.log(ngx.ERR, "Fail to Decode response body, got a no support type!")
    return nil, "ErrNotSupport"
end

function _M.deserialize(data)
    local buf = buf_lib:create_bytes_buff(data)
    return deserialize_buf(buf)
end

function _M.deserialize_multi(data, args_num)
    local ret, rv, err = {}
    local buf = buf_lib:create_bytes_buff(data)
    if args_num ~= nil then
        for i = 1, args_num do --luacheck:ignore
            rv, err = deserialize_buf(buf, nil)
            if err ~= nil then
                return nil, err
            end
            table.insert(ret, rv)
        end
    else
        while (buf:remain() > 0) do
            rv, err = deserialize_buf(buf, nil)
            if err ~= nil then
                if err == "io.EOF" then
                    break
                else
                    return nil, err
                end
            end
            table.insert(ret, rv)
        end
    end
    return ret, err
end

return _M
