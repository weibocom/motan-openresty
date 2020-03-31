-- Copyright (C) idevz (idevz.org)

local consts = require "motan.consts"
local concat = table.concat
local append = table.insert
local sgsub = string.gsub

local ffi = require "ffi"
local motan_tools = ffi.load("motan_tools")
ffi.cdef [[
int get_local_ip(char *, char *);
int get_request_id(uint8_t[8], char *);
int get_request_id_bytes(const char *, char *);
int get_local_ip_from_host_and_port(const char *, int, char *);
]]

local BIGINT_DIVIDER = 0xffffffff + 1

local _M = {
    _VERSION = "0.1.0"
}

function _M.str_2_byte_arr(s)
    local str_len = #s
    -- if(size>8000||(L->top-L->base+size)>8000)
    if str_len < 7000 then
        return {string.byte(s, 1, -1)}
    end
    local req_str = ffi.new("uint8_t[" .. str_len .. "]", s)
    local i = 1
    byte_arr = {}
    while (i <= str_len) do
        byte_arr[i] = req_str[i - 1]
        i = i + 1
    end
    return byte_arr
end

function _M.byte_arr_2_str(buf)
    local len = #buf
    -- if(size>8000||(L->top-L->base+size)>8000)
    -- if len < 7000 then
    --     return string.char(unpack(str_byte_array))
    -- end
    local str_arr = ffi.new("uint8_t[" .. len .. "]", buf)
    local res_str = ffi.new("char[?]", len)
    ffi.copy(res_str, str_arr, len)
    return ffi.string(res_str, len)
end

function _M.pack_request_id(rid_str)
    local rid_num_str = ffi.new("const char *", rid_str)
    local rid_bytes_arr = ffi.new("char[8]")
    motan_tools.get_request_id_bytes(rid_num_str, rid_bytes_arr)
    return ffi.string(rid_bytes_arr, 8)
end

function _M.unpack_request_id(rid_bytes)
    local rid_bytes_arr = ffi.new("uint8_t[8]", rid_bytes)
    local rid_str = ffi.new("char[18]")
    motan_tools.get_request_id(rid_bytes_arr, rid_str)
    return ffi.string(rid_str)
end

function _M.get_local_ip_from_host_and_port(host, port)
    local c_host = ffi.new("const char *", host)
    local c_port = ffi.new("int", port)
    local ip = ffi.new("char[32]")
    motan_tools.get_local_ip_from_host_and_port(c_host, c_port, ip)
    return ffi.string(ip)
end

function _M.get_local_ip()
    local c_str_t = ffi.typeof("char[4]")
    local if_name = ffi.new(c_str_t)
    -- ffi.copy(if_name, "en0")
    -- ffi.copy(if_name, "enp0s5")
    ffi.copy(if_name, "eth0")

    local ip = ffi.new("char[32]")
    motan_tools.get_local_ip(if_name, ip)
    return ffi.string(ip)
end

local next_index = 0
function _M.generate_request_id()
    next_index = next_index + 1
    if next_index > 999 then
        next_index = 0
    end
    return string.format("%d%13d%03d%03d", 1, ngx.now() * 1000, ngx.worker.id(), next_index)
end

function _M.build_service_key(group, version, protocol, path)
    group = group or ""
    version = version or ""
    protocol = protocol or ""
    path = path or ""
    local arr = {
        group,
        "_",
        version,
        "_",
        protocol,
        "_",
        path
    }
    return concat(arr)
end

function _M.is_in_table(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function _M.is_empty(t)
    return t == nil or next(t) == nil
end

local arr_keys = function(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end
_M.arr_keys = arr_keys

function _M.is_assoc(t)
    local orgin_len = #t
    if #t == 0 then
        return true
    end
    t['check_if_is_a_array_or_a_hash'] = false
    local new_len = #arr_keys(t)
    t['check_if_is_a_array_or_a_hash'] = nil
    if new_len - 1 == orgin_len then
        return false
    else
        return true
    end
end

function _M.arr_values(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

function _M.arr_size(t)
    local size = 0
    for _ in pairs(t) do size = size + 1 end
    return size
end

function _M.explode(d, p)
    local t, ll, l
    t = {}
    ll = 0
    if (#p == 1) then
        return {p}
    end
    while true do
        -- find the next d in the string
        l = string.find(p, d, ll, true)
        -- if "not not" found then..
        if l ~= nil then
            -- Save it in our array.
            table.insert(t, string.sub(p, ll, l - 1))
            -- save just after where we found it for searching next time.
            ll = l + 1
        else
            -- Save what's left in our array.
            table.insert(t, string.sub(p, ll))
            -- Break at end, as it should be, according to the lua manual.
            break
        end
    end
    return t
end

function _M.basename(str)
    local name = sgsub(str, "(.*/)(.*)", "%2")
    return name
end

function _M.dirname(str)
    if str:match(".-/.-") then
        local name = sgsub(str, "(.*/)(.*)", "%1")
        return name
    else
        return ""
    end
end

function _M.trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- split function
function _M.split(str, sep)
    local start_index = 1
    local split_index = 1
    local arr = {}
    while true do
        local last_index = string.find(str, sep, start_index)
        if not last_index then
            arr[split_index] = string.sub(str, start_index, string.len(str))
            break
        end
        arr[split_index] = string.sub(str, start_index, last_index - 1)
        start_index = last_index + string.len(sep)
        split_index = split_index + 1
    end
    return arr
end

-- split a path in individual parts
function _M.split_path(str)
    return _M.split(str, "[\\/]+")
end

-- value in table?
function _M.included_in_table(t, value)
    for i = 1, #t do
        if t[i] == value then
            return true
        end
    end
    return false
end

-- reverse table
function _M.reverse_table(t)
    local size = #t + 1
    local reversed = {}
    for i = 1, #t do
        reversed[size - i] = t[i]
    end
    return reversed
end

function _M.split2int(value)
    local lower = value % BIGINT_DIVIDER
    -- @TODO why + 1
    local upper = math.floor((value - lower) / BIGINT_DIVIDER) + 1
    -- local upper = math.floor((value - lower) / BIGINT_DIVIDER)
    return upper, lower
end

function _M.bigint2float(upper, lower)
    return upper * BIGINT_DIVIDER + lower
end



local grab_byte = function(v)
    return math.floor(v / 256), string.char(math.floor(v) % 256)
end

-- Converts an 8-byte little-endian string to a IEEE754 double number
local double_from = function(x)
    local sign = 1
    local mantissa = string.byte(x, 7) % 16
    for i = 6, 1, -1 do mantissa = mantissa * 256 + string.byte(x, i) end
    if string.byte(x, 8) > 127 then sign = -1 end
    local exponent = (string.byte(x, 8) % 128) * 16 +
                     math.floor(string.byte(x, 7) / 16)
    if exponent == 0 then return 0 end
    mantissa = (math.ldexp(mantissa, -52) + 1) * sign
    return math.ldexp(mantissa, exponent - 1023)
end
_M.double_from = double_from

-- Converts a 4-byte little-endian string to a IEEE754 single number
local single_from = function(x)
    local sign = 1
    local mantissa = string.byte(x, 3) % 128
    for i = 2, 1, -1 do mantissa = mantissa * 256 + string.byte(x, i) end
    if string.byte(x, 4) > 127 then sign = -1 end
    local exponent = (string.byte(x, 4) % 128) * 2 +
                     math.floor(string.byte(x, 3) / 128)
    if exponent == 0 then return 0 end
    mantissa = (math.ldexp(mantissa, -23) + 1) * sign
    return math.ldexp(mantissa, exponent - 127)
end
_M.single_from = single_from

-- Converts a IEEE754 single number to a 4-byte little-endian string
local single_to = function(x)
    local sign = 0
    if x < 0 then sign = 1; x = -x end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then -- zero
      mantissa = 0; exponent = 0
    else
      mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
      exponent = exponent + 126
    end
    local v, byte = "" -- convert to bytes
    x, byte = grab_byte(mantissa); v = v..byte -- 7:0
    x, byte = grab_byte(x); v = v..byte -- 15:8
    x, byte = grab_byte(exponent * 128 + x); v = v..byte -- 23:16
    x, byte = grab_byte(sign * 128 + x); v = v..byte -- 31:24
    return v
end
_M.single_to = single_to

-- Converts a IEEE754 double number to an 8-byte little-endian string
local double_to = function(x)
    local sign = 0
    if x < 0 then sign = 1; x = -x end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then -- zero
      mantissa, exponent = 0, 0
    else
      mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
      exponent = exponent + 1022
    end
    local v, byte = "" -- convert to bytes
    x = mantissa
    for i = 1,6 do
      x, byte = grab_byte(x); v = v..byte -- 47:0
    end
    x, byte = grab_byte(exponent * 16 + x); v = v..byte -- 55:48
    x, byte = grab_byte(sign * 128 + x); v = v..byte -- 63:56
    return v
end
_M.double_to = double_to

-- Read an integer in LSB order.
function _M.lsb_stringtonumber(str)
    local function _b2n(exp, num, digit, ...)
        if not digit then
            return num
        end
        return _b2n(exp * 256, num + digit * exp, ...)
    end
    return _b2n(256, string.byte(str, 1, -1))
end

-- Read an integer in MSB order.
function _M.msb_stringtonumber(str)
    local function _b2n(num, digit, ...)
        if not digit then
            return num
        end
        return _b2n(num * 256 + digit, ...)
    end
    return _b2n(0, string.byte(str, 1, -1))
end

-- Write an integer in MSB order using width bytes.
function _M.msb_numbertobytes(number, widths)
    local function _n2b(t, width, num, rem)
        if width == 0 then
            return table.concat(t)
        end
        table.insert(t, 1, string.char(rem * 256))
        return _n2b(t, width - 1, math.modf(num / 256))
    end
    return _n2b({}, widths, math.modf(number / 256))
end

function _M.f(num)
    local floor = math.floor
    local function fn(t, n)
        table.insert(t, 1, n % 2)
        local rem = floor(n / 2)
        if rem == 0 then
            return t
        end
        return fn(t, rem)
    end
    return table.concat(fn({}, num), "")
end

function _M.amsb_numbertobytes(num, width)
    local bit = bit
    local rs = {}
    num = bit.tobit(num)
    for i = 0, (width - 1) * 8, 8 do
        table.insert(rs, 1, string.char(bit.band(bit.rshift(num, i), 0xff)))
    end
    return table.concat(rs)
end

-- Write an integer in MSB order using width bytes.
function _M.xmsb_numbertobytes(num, width)
    -- if num > bit.lshift(1, width * 8) - 1 then
    --     error("number width overflow")
    -- end
    local bit = require("bit")
    local rs = {}
    local band = 0xff
    for i = 1, width do
        table.insert(rs, 1, string.char(bit.rshift(bit.band(num, band), 8 * (i - 1))))
        band = bit.lshift(band, 8)
    end
    return table.concat(rs)
end

-- Write an integer in LSB order using width bytes.
function _M.lsb_numbertobytes(number, widths)
    local function _n2b(width, num, rem)
        rem = rem * 256
        if width == 0 then
            return rem
        end
        return rem, _n2b(width - 1, math.modf(num / 256))
    end
    return string.char(_n2b(widths - 1, math.modf(number / 256)))
end

function _M.motan_table_type(v)
    local data_type, err
    local orgin_len = #v
    local add_one_len = 0
    local v_type = nil
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

--- get the Lua keywords as a set-like table.
-- So `res["and"]` etc would be `true`.
-- @return a table
function _M.get_keywords()
    local lua_keyword = {
        ["and"] = true,
        ["break"] = true,
        ["do"] = true,
        ["else"] = true,
        ["elseif"] = true,
        ["end"] = true,
        ["false"] = true,
        ["for"] = true,
        ["function"] = true,
        ["if"] = true,
        ["in"] = true,
        ["local"] = true,
        ["nil"] = true,
        ["not"] = true,
        ["or"] = true,
        ["repeat"] = true,
        ["return"] = true,
        ["then"] = true,
        ["true"] = true,
        ["until"] = true,
        ["while"] = true
    }
    return lua_keyword
end

-- Utility function that finds any patterns
-- that match a long string's an open or close.
-- Note that having this function use the least number of equal signs
-- that is possible is a harder algorithm to come up with.
-- Right now, it simply returns the greatest number of them found.
-- @param s The string
-- @return 'nil' if not found. If found,
-- the maximum number of equal signs found within all matches.
local function has_lquote(s)
    local lstring_pat = "([%[%]])(=*)%1"
    local finish, start, equals, next_equals = 0
    -- print("checking lquote for", s)
    repeat
        start, finish, next_equals = s:find(lstring_pat, finish + 1)
        if start then
            -- print("found start", start, finish, next_equals)
            --length of captured =. Ex: [==[ is 2, ]] is 0.
            next_equals = #next_equals
            equals = next_equals >= (equals or 0) and next_equals or equals
        end
    until not start
    --next_equals will be nil if there was no match.
    return equals
end

-- Quote the given string and preserve any control or escape characters,
-- such that reloading the string in Lua returns the same result.
-- @param s The string to be quoted.
-- @return The quoted string.
function _M.quote_string(s)
    --find out if there are any embedded long-quote
    --sequences that may cause issues.
    --This is important when strings are embedded within strings
    -- , like when serializing.
    local equal_signs = has_lquote(s)
    if s:find("\n") or equal_signs then
        -- print("going with long string:", s)
        equal_signs = ("="):rep((equal_signs or -1) + 1)
        --long strings strip out leading \n.
        -- We want to retain that, when quoting.
        if s:find("^\n") then
            s = "\n" .. s
        end
        --if there is an embedded sequence that matches a long quote, then
        --find the one with the maximum number of
        --  = signs and add one to that number
        local lbracket, rbracket = "[" .. equal_signs .. "[", "]" .. equal_signs .. "]"
        s = lbracket .. s .. rbracket
    else
        --Escape funny stuff.
        s = ("%q"):format(s)
    end
    return s
end

local function quote(s)
    if type(s) == "table" then
        return _M.write(s, "")
    else
        -- ('%q'):format(tostring(s))
        --AAS
        return _M.quote_string(s)
    end
end

local function quote_if_necessary(v)
    if not v then
        return ""
    else
        --AAS
        if v:find " " then
            v = _M.quote_string(v)
        end
    end
    return v
end

local function index(numkey, key)
    --AAS
    if not numkey then
        key = quote(key)
        key = key:find("^%[") and (" " .. key .. " ") or key
    end
    return "[" .. key .. "]"
end

local function is_identifier(s)
    local keywords = _M.get_keywords()
    return type(s) == "string" and s:find("^[%a_][%w_]*$") and not keywords[s]
end

--- Create a string representation of a Lua table.
--  This function never fails, but may complain by returning an
--  extra value. Normally puts out one item per line, using
--  the provided indent; set the second parameter to '' if
--  you want output on one line.
--  @tab tbl Table to serialize to a string.
--  @string space (optional) The indent to use.
--  Defaults to two spaces; make it the empty string for no indentation
--  @bool not_clever (optional) Use for plain output, e.g {['key']=1}.
--  Defaults to false.
--  @return a string
--  @return a possible error message
function _M.write(tbl, space, not_clever)
    if type(tbl) ~= "table" then
        local res = tostring(tbl)
        if type(tbl) == "string" then
            return quote(tbl)
        end
        return res, "not a table"
    end
    local set = " = "
    if space == "" then
        set = "="
    end
    space = space or "  "
    local lines = {}
    local line = ""
    local tables = {}

    local function put(s)
        if #s > 0 then
            line = line .. s
        end
    end

    local function putln(s)
        if #line > 0 then
            line = line .. s
            append(lines, line)
            line = ""
        else
            append(lines, s)
        end
    end

    local function eat_last_comma()
        local n = #lines
        local lastch = lines[n]:sub(-1, -1)
        if lastch == "," then
            lines[n] = lines[n]:sub(1, -2)
        end
    end

    local writeit
    writeit = function(t, oldindent, indent)
        local tp = type(t)
        if tp ~= "string" and tp ~= "table" then
            putln(quote_if_necessary(tostring(t)) .. ",")
        elseif tp == "string" then
            -- if t:find('\n') then
            --     putln('[[\n'..t..']],')
            -- else
            --     putln(quote(t)..',')
            -- end
            --AAS
            putln(_M.quote_string(t) .. ",")
        elseif tp == "table" then
            if tables[t] then
                putln("<cycle>,")
                return
            end
            tables[t] = true
            local newindent = indent .. space
            putln("{")
            local used = {}
            if not not_clever then
                for i, val in ipairs(t) do
                    put(indent)
                    writeit(val, indent, newindent)
                    used[i] = true
                end
            end
            for key, val in pairs(t) do
                local numkey = type(key) == "number"
                if not_clever then
                    key = tostring(key)
                    put(indent .. index(numkey, key) .. set)
                    writeit(val, indent, newindent)
                else
                    if not numkey or not used[key] then -- non-array indices
                        if numkey or not is_identifier(key) then
                            key = index(numkey, key)
                        end
                        put(indent .. key .. set)
                        writeit(val, indent, newindent)
                    end
                end
            end
            tables[t] = nil
            eat_last_comma()
            putln(oldindent .. "},")
        else
            putln(tostring(t) .. ",")
        end
    end
    writeit(tbl, "", space)
    eat_last_comma()
    return concat(lines, #space > 0 and "\n" or "")
end

function _M.sprint_r(o)
    return _M.write(o)
end

local print_b = function(buf, index)
    local index = index or 0
    local res_arr = {string.byte(buf, 1, -1)}
    -- print_r(res_arr)
    for i,v in ipairs(res_arr) do
        print(i - 2 + index,v)
    end
    print(#res_arr)
end
_M.print_b = print_b

function _M.access_log(...)
    ngx.log(ngx.STDERR, ...)
end

local deepcopy 
deepcopy = function(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
_M.deepcopy = deepcopy

return _M
