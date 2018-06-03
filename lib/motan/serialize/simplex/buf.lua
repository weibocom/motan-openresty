-- Copyright (C) idevz (idevz.org)


-- @TODO check LuaJIT bit 32
-- rlwrap /usr/local/bin/v-console-0.1.0.rc7
-- openresty-1.13.6.1-gdb/build/LuaJIT-2.1-20171103/src
local setmetatable = setmetatable
local utils = require "motan.utils"
local consts = require "motan.consts"
local str_len = string.len
local ngx_re_find = ngx.re.find
local bit = require "bit"
local maxn = table.maxn
local lshift = bit.lshift
local rshift = bit.rshift
local bor = bit.bor
local bxor = bit.bxor
local band = bit.band

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {nil, [narr]=0} end
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new_bytes_buff(self, initsize)
    return self:new({
        byte_arr_buf = new_tab(initsize, 0)
    })
end

function _M.create_bytes_buff(self, data)
    local wpos = 1
    if data ~= nil then
        wpos = #data
    end
    return self:new({
        byte_str_buf = data,
        wpos = wpos
    })
end

function _M.new(self, opts)
    local order = opts.order or consts.BYTE_ORDER_BIG_ENDIAN
    local numbertobytes = utils.msb_numbertobytes
    local stringtonumber = utils.msb_stringtonumber
    if order == consts.BYTE_ORDER_LITTLE_ENDIAN then
        numbertobytes = utils.lsb_numbertobytes
        stringtonumber = utils.lsb_stringtonumber
    end
    local bytes = {
        byte_arr_buf = opts.byte_arr_buf or new_tab(8, 0),
        byte_str_buf = opts.byte_str_buf or "",
        rpos = opts.rpos or 1,
        wpos = opts.wpos or 1,
        order = order,
        numbertobytes = numbertobytes,
        stringtonumber = stringtonumber,
        temp = nil
    }
    return setmetatable(bytes, mt)
end

function _M.set_wpos(self, pos)
    self.wpos = pos
end

function _M.get_wpos(self)
    return self.wpos
end

function _M.set_rpos(self, pos)
    self.rpos = pos
end

function _M.get_rpos(self)
    return self.rpos
end

local copy
copy = function(byte_arr_buf, old_byte_arr_buf)
    local b_wpos = #byte_arr_buf
    local old_wpos = #old_byte_arr_buf
    local num = 0
    for i=1,old_wpos do
        byte_arr_buf[b_wpos + i] = old_byte_arr_buf[i]
        num = num + 1
    end
    return num
end

--[[
if is a byte array, when use table.concat it 
will got a number string, which won't contain any alphabet.
]]--
local check_byte_arr
check_byte_arr = function(byte_arr)
    local ok, byte_concat_str = pcall(table.concat, byte_arr, "")
    if not ok then
        return false
    end
    local have_str = ngx_re_find(byte_concat_str, "[a-z]|[A-Z]", "jo")
    if have_str then
        return false
    end
    return true
end

function _M.write_byte(self, c)
    if not type(c) == "number" then
        ngx.log(ngx.ERR, "write_byte paramete err, it's not a number.\n")
        error("write_byte paramete err, it's not a number.\n")
    end
    
    table.insert(self.byte_arr_buf, self.wpos, c)
    self.wpos = self.wpos + 1

end

function _M.write(self, bytes)
    local is_byte_arr = check_byte_arr(bytes)
    if not is_byte_arr then
        ngx.log(ngx.ERR, "write paramete err, it's not a byte array.\n")
        error("write paramete err, it's not a byte array.\n")
    end
    local l = #bytes

    
    local i = 1
    local from = self.wpos
    for from = self.wpos, from + l + 1 do
        table.insert(self.byte_arr_buf, from, bytes[i])
        i = i + 1
    end

    self.wpos = self.wpos + l

end

-- for length
function _M.insert_uint(self, u)
    if not type(u) == "number" then
        ngx.log(ngx.ERR, "write_uint paramete err, it's not a number.\n")
        error("write_uint paramete err, it's not a number.\n")
    end
    
    local num_byte_str = self.numbertobytes(u, 4)
    self.temp = {string.byte( num_byte_str, 1, -1 )}

    local l = #self.temp

    local i = 1
    local from = self.wpos
    for from = self.wpos, from + l - 1 do
        self.byte_arr_buf[from] = self.temp[i]
        i = i + 1
    end
    self.wpos = self.wpos + l

end

local write_uint
write_uint = function(self, u, width)
    if not type(u) == "number" then
        ngx.log(ngx.ERR, "write_uint paramete err, it's not a number.\n")
        error("write_uint paramete err, it's not a number.\n")
    end

    local num_byte_str = self.numbertobytes(u, width)
    self.temp = {string.byte( num_byte_str, 1, -1 )}

    local l = #self.temp
    if l ~= width then
        ngx.log(ngx.ERR, "Err to write a uint")
        error("Err to write a uint")
    end

    local i = 1
    local from = self.wpos
    for from = self.wpos, from + l + 1 do
        table.insert(self.byte_arr_buf, from, self.temp[i])
        i = i + 1
    end
    self.wpos = self.wpos + l

end

function _M.write_uint16(self, u)
    write_uint(self, u, 2)
end

function _M.write_uint32(self, u)
    write_uint(self, u, 4)
end

function _M.write_uint64(self, u)
    write_uint(self, u, 8)
end

function _M.write_zigzag32(self, u)
    return self:write_varint(bxor(lshift(u, 1), rshift(u, 31)))
end

function _M.write_zigzag64(self, u)
    return self:write_varint(bxor(lshift(u, 1), rshift(u, 63)))
end

function _M.write_varint(self, u)
    local l = 0
    while u >= lshift(1,7) do
        self:write_byte((bor(band(u, 0x7f), 0x80)))
        u = rshift(u, 7)
        l = l + 1
    end
    self:write_byte(u)
    l = l + 1
    return l
end

function _M.bytes(self)
    return self.byte_arr_buf
end

function _M.read(self, p)
    if self.rpos >= #self.byte_str_buf then
        return 0, "io.EOF"
    end
    p = {string.sub( self.byte_str_buf, self.rpos, self.rpos + #p - 1 ):byte(1, -1)}
    self.rpos = self.rpos + #p
    return #p, nil
end

function _M.read_full(self, p)
    if self:remain() < #p then
        return "ErrNotEnough"
    end
    p = {string.sub( self.byte_str_buf, self.rpos ):byte(1, -1)}
    self.rpos = self.rpos + #p
    return nil
end

local read_uint
read_uint = function(self, width)
    if self:remain() < width then
        return 0, "ErrNotEnough"
    end
    local n = self.stringtonumber(string.sub( self.byte_str_buf, self.rpos, self.rpos + width -1 ))
    self.rpos = self.rpos + width
    return n, nil
end

function _M.read_uint16(self)
    return read_uint(self, 2)
end

function _M.read_int(self)
    return self:read_uint32()
end

function _M.read_uint32(self)
    return read_uint(self, 4)
end

function _M.read_uint64(self)
    return read_uint(self, 8)
end

function _M.read_zigzag64(self)
    local x, err = self:read_varint()
    if err ~= nil then
        return nil, err
    end
    x = rshift(x, 1) ^ rshift(lshift(band(x, 1), 63), 63)
    return x, nil
end

function _M.read_zigzag32(self)
    local x, err = self:read_varint()
    if err ~= nil then
        return nil, err
    end
    x = bxor(rshift(x, 1), rshift(lshift(band(x, 1), 31), 31))
    return x, nil
end

-- @TODO check read_varint
function _M.read_varint(self)
    local temp = 0
    local x = 0
    local offset = 0
    while (offset < 30)
    do
        local temp, err = self:read_byte()
        if err ~= nil then
            return 0, err
        end
        if band(temp, 0x80) ~= 0x80 then
            x = bor(x, lshift(temp, offset))
            return x, nil
        end
        x = bor(x, lshift(band(temp, 0x7f), offset))
        offset = offset + 7
    end
    return 0, "ErrOverflow"
end

function _M.next(self, n)
    local m = self:remain()
    if n > m then
        return nil, "ErrNotEnough"
    end
    local data = {string.sub( self.byte_str_buf, self.rpos, self.rpos + n - 1 ):byte(1, -1)}
    self.rpos = self.rpos + n
    return data, nil
end

function _M.read_byte(self)
    if self.rpos > #self.byte_str_buf then
        return 0, "io.EOF"
    end
    local data = string.sub( self.byte_str_buf, self.rpos, self.rpos ):byte()
    self.rpos = self.rpos + 1
    return data, nil
end

function _M.reset(self)
    self.rpos = 1
    self.wpos = 1
end

function _M.remain(self)
    return self.wpos - self.rpos + 1
end

function _M.len(self)
    return self.wpos - 0
end

function _M.cap(self)
    return maxn(self.byte_arr_buf)
end

return _M
