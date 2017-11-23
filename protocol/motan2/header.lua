-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local setmetatable = setmetatable
local utils = require "motan.utils"

local bit = require "bit"
local lshift = bit.lshift
local rshift = bit.rshift
local bor = bit.bor
local band = bit.band

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, opts)
    local m2header = {
        magic = consts.MOTAN_MAGIC, 
        msg_type = opts.msg_type or 0, 
        version_status = opts.version_status or 0, 
        serialize = opts.serialize or 0, 
        request_id = opts.request_id or ngx.now(), 
    }
    return setmetatable(m2header, mt)
end

function _M.pack_header(self)
    local header_buffer = utils.msb_numbertobytes(0xF1F1, 2)
    header_buffer = header_buffer .. utils.msb_numbertobytes(self.msg_type, 1)
    header_buffer = header_buffer .. utils.msb_numbertobytes(self.version_status, 1)
    header_buffer = header_buffer .. utils.msb_numbertobytes(self.serialize, 1)
    -- @TODO big num pack to bytes
    header_buffer = header_buffer .. utils.msb_numbertobytes(self.request_id, 8)
    -- header_buffer = header_buffer .. self.request_id
    -- local upper, lower = utils.split2int(self.request_id)
    -- header_buffer = header_buffer .. utils.msb_numbertobytes(upper, 4)
    -- header_buffer = header_buffer .. utils.msb_numbertobytes(lower, 4)
    return header_buffer
end

function _M.set_version(self, version)
    if version > 31 then
        error('motan header: version should not great than 31')
    end
    self.version_status = bor(band(self.version_status, 0x07), band(lshift(version, 3), 0xf8))
end

function _M.get_version(self)
    return tonumber(band(rshift(self.version_status, 3), 0x1f), 16)
end

function _M.set_heartbeat(self, is_heartbeat)
    if true == is_heartbeat then
        self.msg_type = bor(self.msg_type, 0x10)
    else
        self.msg_type = band(self.msg_type, 0xef)
    end
end

function _M.is_heartbeat(self)
    return band(self.msg_type, 0x10) == 0x10
end

function _M.set_gzip(self, is_gzip)
    if true == is_gzip then
        self.msg_type = bor(self.msg_type, 0x08)
    else
        self.msg_type = band(self.msg_type, 0xf7)
    end
end

function _M.is_gzip(self)
    return band(self.msg_type, 0x08) == 0x08
end

function _M.set_oneWay(self, is_one_way)
    if true == is_one_way then
        self.msg_type = bor(self.msg_type, 0x04)
    else
        self.msg_type = band(self.msg_type, 0xfb)
    end
end

function _M.is_oneWay(self)
    return band(self.msg_type, 0x04) == 0x04
end

function _M.set_proxy(self, is_proxy)
    if true == is_proxy then
        self.msg_type = bor(self.msg_type, 0x02)
    else
        self.msg_type = band(self.msg_type, 0xfd)
    end
end

function _M.is_proxy(self)
    return band(self.msg_type, 0x02) == 0x02
end

function _M.set_request(self, is_request)
    if true == is_request then
        self.msg_type = band(self.msg_type, 0xfe)
    else
        self.msg_type = bor(self.msg_type, 0x01)
    end
end

function _M.is_request(self)
    return band(self.msg_type, 0x01) == 0x00
end

function _M.set_status(self, status)
    if status > 7 then
        error('motan header: status should not great than 7')
    end
    self.version_status = bor(band(self.version_status, 0xf8), band(status, 0x07))
end

function _M.get_status(self)
    return tonumber(band(self.version_status, 0x07), 16)
end

function _M.set_serialize(self, serialize)
    if serialize > 31 then
        error('motan header: serialize should not great than 31')
    end
    self.serialize = bor(band(self.serialize, 0x07), band(lshift(serialize, 3), 0xf8))
end

function _M.get_serialize(self)
    return band(rshift(self.serialize, 3), 0x1f)
end

return _M
