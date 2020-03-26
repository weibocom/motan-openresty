-- Copyright (C) idevz (idevz.org)

local utils = require "motan.utils"
local consts = require "motan.consts"
local brz_w = require "resty.breeze.writer"
local brz_r = require "resty.breeze.reader"
local brz_buf = require "resty.breeze.bbuf"

local ffi = require "ffi"
local C = ffi.C

local breeze = ffi.load("breeze")

local _M = {
    _VERSION = "0.1.0"
}

ffi.cdef([[
typedef struct {
	uint8_t *buffer;
	byte_order_t order;
	uint32_t write_pos;
	uint32_t read_pos;
	size_t capacity;
	uint8_t _read_only;
} breeze_bytes_buf_t;

extern breeze_bytes_buf_t *
breeze_new_bytes_buf(size_t capacity, byte_order_t order);

extern breeze_bytes_buf_t *
breeze_new_bytes_buf_from_bytes(const uint8_t *raw_bytes, size_t size, byte_order_t order, uint8_t read_only);

extern void breeze_free_bytes_buffer(breeze_bytes_buf_t *bb);

extern void bb_write_bytes(breeze_bytes_buf_t *bb, const uint8_t *bytes, int len);

extern void bb_write_byte(breeze_bytes_buf_t *bb, uint8_t u);

extern void bb_write_uint16(breeze_bytes_buf_t *bb, uint16_t u);

extern void bb_write_uint32(breeze_bytes_buf_t *bb, uint32_t u);

extern void bb_write_uint64(breeze_bytes_buf_t *bb, uint64_t u);

extern void bb_write_varint(breeze_bytes_buf_t *bb, uint64_t u, int *len);

extern void bb_set_write_pos(breeze_bytes_buf_t *bb, uint32_t pos);

extern void bb_set_read_pos(breeze_bytes_buf_t *bb, uint32_t pos);

extern int bb_remain(breeze_bytes_buf_t *bb);

extern void bb_reset(breeze_bytes_buf_t *bb);

extern int bb_read_bytes(breeze_bytes_buf_t *bb, uint8_t *bs, int len);

extern int bb_read_byte(breeze_bytes_buf_t *bb, uint8_t *u);

extern int bb_read_uint16(breeze_bytes_buf_t *bb, uint16_t *u);

extern int bb_read_uint32(breeze_bytes_buf_t *bb, uint32_t *u);

extern int bb_read_uint64(breeze_bytes_buf_t *bb, uint64_t *u);

extern int bb_read_zigzag32(breeze_bytes_buf_t *bb, uint64_t *u);

extern int bb_read_zigzag64(breeze_bytes_buf_t *bb, uint64_t *u);

extern int bb_read_varint(breeze_bytes_buf_t *bb, uint64_t *u);
]])

function _M.serialize(param)
    local bbuf = brz_buf.breeze_new_bytes_buf(256, breeze.B_BIG_ENDIAN)
    brz_w.write_value(bbuf, param)
    return ffi.string(bbuf.buf.buffer, bbuf.buf.write_pos), nil
end

function _M.serialize_multi(params)
    if utils.is_empty(params) then
        return nil, nil
    end
    local bbuf = brz_buf.breeze_new_bytes_buf(256, breeze.B_BIG_ENDIAN)
    for _,param in ipairs(params) do
        brz_w.write_value(bbuf, param)
    end
    return ffi.string(bbuf.buf.buffer, bbuf.buf.write_pos), nil
end

function _M.get_serialize_num()
    return consts.MOTAN_SERIALIZE_BREEZE
end

function _M.deserialize(data)
    local bbuf = brz_buf.breeze_new_bytes_buf_from_bytes(data,
        #data, breeze.B_BIG_ENDIAN, 1)
    
    local ok, res, err = pcall(brz_r.read_value, bbuf)
    if not ok then
        return nil, err
    end

    return res, nil
end

function _M.deserialize_multi(data, args_num)
    local res, err = {}
    local data_len = #data
    local bbuf = brz_buf.breeze_new_bytes_buf_from_bytes(data,
        data_len, breeze.B_BIG_ENDIAN, 1)
    if args_num ~= nil then
        for i=1,args_num do
            local tmp, err = brz_r.read_value(bbuf)
            if err ~= nil then
                return nil, err
            end
            table.insert(res, tmp)
        end
    else
        while(bbuf.buf.read_pos < data_len) do
            local tmp, err = brz_r.read_value(bbuf)
            if err ~= nil then
                if bbuf.buf.read_pos == data_len then
                    break
                end
                return nil, err
            end
            table.insert(res, tmp)
        end
    end
    return res, nil
end

return _M
