-- Copyright (C) idevz (idevz.org)


local sub = string.sub
local byte = string.byte
local tcp = ngx.socket.tcp
local null = ngx.null
local type = type
local pairs = pairs
local unpack = unpack
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local rawget = rawget
local error = error
local consts = require "motan.consts"
local header = require "motan.protocol.m2header"
local message = require "motan.protocol.message"
local utils = require "motan.utils"
local bit = require "bit"
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    local motan_ep = {
        url = opts.url or {},
        _sock = sock,
    }
    return setmetatable(motan_ep, mt)
end

function _M.set_timeout(self, timeout)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end


function _M.connect(self, ...)
    local sock = rawget(self, "_sock")
    if not sock then
        return nil, "not initialized"
    end
    return sock:connect(self.url.host, self.url.port)
end

local function _read_reply(self, sock)
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
            metadata[key] = metadata_arr[i +1 ]
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
    return msg
end

function _M.call(self, req)
    local req_buf = req:encode()
    local sock = rawget(self, "_sock")
    local ok, err = self:connect()
    if ok then
        local bytes, err = sock:send(req_buf)
        if not bytes then
            ngx.log(ngx.ERR, "motan endpoint send RPC Call err: ", err)
            return nil, err
        end
        local resp_ok, resp_err = _read_reply(self, sock)
        if not resp_ok then
            ngx.log(ngx.ERR, "motan endpoint receive RPC resp err: ", resp_err)
            return nil, err
        end
        sock:setkeepalive(5000, 100)
        return resp_ok
    else
        ngx.log(ngx.ERR, "motan endpoint failed connect to peer: ", err)
        return nil, err
    end
end

return _M
