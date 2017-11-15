-- Copyright (C) idevz (idevz.org)


local tcp = ngx.socket.tcp
local setmetatable = setmetatable
local rawget = rawget
local singletons = require "motan.singletons"

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M.new(self, url)
    local motan_ep = {
        url = url, 
        _sock = {}, 
    }
    return setmetatable(motan_ep, mt)
end

function _M.initialize(self)
end

function _M.destroy(self)
end

function _M.set_proxy(self, proxy)
end

function _M.set_serialization(self, serialization)
end

function _M.get_name(self)
end

function _M.get_url(self)
    return self.url
end

function _M.set_url(self, url)
end

function _M.is_available(self)
    return true
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

function _M.call(self, req)
    local start_time = ngx.now()
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    rawset(self, "_sock", sock)
    local ok, err = self:connect()
    local protocol = singletons.motan_ext:get_protocol(self.url.protocol)
    if ok then
        local serialization = singletons.motan_ext:get_serialization(self.url.params["serialization"])
        local req_buf = protocol:convert_to_request_msg(req, serialization)
        local bytes, err = sock:send(req_buf)
        if not bytes then
            ngx.log(ngx.ERR, "motan endpoint send RPC Call err: ", err)
            return protocol:build_error_resp(err, req)
        end
        local resp_ok, resp_err = protocol:read_reply(sock, serialization)
        if not resp_ok then
            ngx.log(ngx.ERR, "motan endpoint receive RPC resp err: ", resp_err)
            return protocol:build_error_resp(resp_err, req)
        end
        sock:setkeepalive(5000, 100)
        local process_time = ngx.now() - start_time
        resp_ok:set_process_time(math.floor((process_time * 100) + 0.5) * 0.01)
        return resp_ok
    else
        ngx.log(ngx.ERR, "motan endpoint failed connect to peer: ", err)
        return protocol:build_error_resp(err, req)
    end
end

return _M
