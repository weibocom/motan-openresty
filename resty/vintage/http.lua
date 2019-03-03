-- Copyright (C) idevz (idevz.org)


local cjson = require('cjson')
local json_decode = cjson.decode
local json_encode = cjson.encode
local ngx = ngx
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_DEBUG = ngx.DEBUG
local ngx_encode_args = ngx.encode_args
local http = require('resty.http')

local _M = {
    _VERSION = '0.01',
}

local DEFAULT_TIMEOUT  = 60*1000 -- 60s default timeout
local MAX_IDLE_TIMEOUT = 60*1000 -- 60s default timeout
local POOL_SIZE        = 20

local mt = { __index = _M }


function _M:new(opts)
    local http_t = {
        connect_timeout     = opts.connect_timeout     or DEFAULT_TIMEOUT,
        read_timeout        = opts.read_timeout        or DEFAULT_TIMEOUT,
        max_idle_timeout    = opts.max_idle_timeout    or MAX_IDLE_TIMEOUT,
        pool_size           = opts.pool_size           or POOL_SIZE,
    }
    return setmetatable(http_t, mt)
end


local function safe_json_decode(json_str)
    local ok, json = pcall(json_decode, json_str)
    if ok then
        return json
    else
        ngx_log(ngx_ERR, json)
    end
end


local function connect(self)
    local httpc = http.new()

    local connect_timeout = self.connect_timeout
    httpc:set_timeout(connect_timeout)

    return httpc
end


local function _get(httpc, uri)
    local res, err = httpc:request_uri(uri, {method = "GET"})
    if not res then
        return nil, err
    end

    local status = res.status
    if not status then
        return nil, "No status from vintage"
    end

    return res
end


function _M:get(uri)
    local httpc, err = connect(self)
    if not httpc then
        return nil, err
    end

    local read_timeout    = self.read_timeout
    httpc:set_timeout(read_timeout)

    local res, err = _get(httpc, uri)
    httpc:set_keepalive(self.max_idle_timeout, self.pool_size)
    if not res then
        return nil, err
    end

    return res, err
end


function _M:post(uri, data)
    local httpc, err = connect(self)
    if not httpc then
        return nil, err
    end

    local body_in
    if type(data) == "table" or type(data) == "boolean" then
        body_in = ngx.encode_args(data)
    else
        body_in = data
    end

    local res, err = httpc:request_uri(uri, {
        method = "POST",
        body = body_in,
        headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })
    if not res then
        return nil, err
    end

    if not res.status then
        return nil, "No status from Vintage."
    end
    
    local body = res.body
    httpc:set_keepalive(self.max_idle_timeout, self.pool_size)

    -- If status is not 200 then body is most likely an error message
    if res.status ~= 200 then
        return nil, body
    elseif body and #body > 0 then
        return body
    else
        return true
    end
end


return _M
