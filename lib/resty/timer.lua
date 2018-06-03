-- Copyright (C) idevz (idevz.org)


local json = require("cjson.safe")
local check_params
check_params = function(p, t)
    if p ~=nil
    and type(p) == t then
        return p
    else
        error("Params error type of get null.")
    end
end

local call
call = function(self, caller, k, d, cback, ...)
    local self       = self
    local caller     = caller
    local key        = check_params(k, "string")
    local delay      = check_params(d, "number")
    self.callback    = check_params(cback, "function")

    if self.only_one then
        if ngx.worker.id() == 0 then
            caller(delay, self.timer_callback, key, self, ...)
        end
        return self
    else
        caller(delay, self.timer_callback, key, self, ...)
    end
    return self
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M:new(only_one_worker, shm)
    local only_one = only_one_worker or false
    local shm = shm
    local t_timer = {
        -- delay = delay,
        NO_RES = "NO_RES",
        callback = nil,
        only_one = only_one,
        shm = shm,
        res_multi = {},
        res = {}
    }
    return setmetatable(t_timer, mt)
end

function _M:timer_callback(...)
    local key = select(1, ...)
    local self = select(2, ...)
    local shm = self.shm
    -- 规范返回结果
    local res, err = self.callback(select(3, ...))
    if err ~= nil then
        ngx.log(ngx.ERR, "\ntimer_callback error:\n", err, debug.traceback())
        return nil, err
    end
    if key == self.NO_RES then
        return
    end
    self.res_multi[key] = res
    if self.only_one then
        local rs, err = shm:get(key)
        if rs == nil then
            shm:set(key, json.encode(res))
        else
            shm:replace(key, json.encode(res))
        end
    end
end

function _M:tick(k, d, cback, ...)
    return call(self, ngx.timer.every, k, d, cback, ...)
end

function _M:run(k, d, cback, ...)
    return call(self, ngx.timer.at, k, d, cback, ...)
end

function _M:get_all_res()
    return self.res_multi
end

function _M:get_res(key)
    local res
    local shm = self.shm    
    if self.only_one then
        res = json.decode(shm:get(key))
        if not res then
            res = self.res_multi[key]
        end
        return res
    end
    if key ~= nil and self.res_multi[key] ~= nil then
        res = self.res_multi[key]
    end
    return res
end

return _M