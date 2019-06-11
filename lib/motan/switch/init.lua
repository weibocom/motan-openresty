-- Copyright (C) idevz (idevz.org)

local consts = require "motan.consts"
local utils = require "motan.utils"
local timer = require "resty.timer"
local switch_shm = ngx.shared[consts.MOTAN_SWITCHER_SHM_KEY]
local setmetatable = setmetatable

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}
local DEFAULT_TIME_OUT = 2 * 3600 * 1000
local DEFAULT_CHECK_INTERVAL = 1
local switcher_set = {}

-- printf "on resource feature.motanrpc.vintage.service.200\r\n" | nc 127.0.0.1 2234 > /dev/null
-- printf "on resource feature.motanrpc.vintage.service.503\r\n" | nc 127.0.0.1 2234 > /dev/null

switcher_set[consts.MOTAN_SWITCHER_503] = consts.MOTAN_SWITCHER_503
switcher_set[consts.MOTAN_SWITCHER_200] = consts.MOTAN_SWITCHER_200

local switch_handler = function(switcher, switcher_value)
    if switch_shm == nil then
        return
    end
    switch_shm:set(switcher, switcher_value)
    ngx.log(ngx.NOTICE, "switch set ", switcher, " to:", switcher_value)
end

local function reset_switch(switcher)
    switch_shm:delete(switcher)
    ngx.log(ngx.NOTICE, "switcher ", switcher, " has been reset.")
end

function _M.new(self)
    local handler = {}
    return setmetatable(handler, mt)
end

function _M.run(self)
    local sock = assert(ngx.req.socket(true))
    sock:settimeout(DEFAULT_TIME_OUT)
    while not ngx.worker.exiting() do
        local switch_content = sock:receive([[*l]])
        if not switch_content or switch_content == "" then
            ngx.say("fail to get switch content, nothing input.")
        end
        ngx.log(ngx.NOTICE, "get switch_content: ", switch_content)
        local switcher_value, _, switcher = unpack(utils.split(switch_content, consts.MOTAN_SWITCHER_SEPERATOR))
        ngx.log(ngx.NOTICE, "switch ", switcher, " try to be set value is ", switcher_value)
        if switcher_set[switcher] ~= nil then
            switch_handler(switcher, switcher_value)
        else
            ngx.log(ngx.ERR, "empty switcher_set for switcher: ", swhitcher)
        end
        break
    end
end

local function switch_check_handle(switcher, switcher_value, exporter_obj)
    if switcher_value == "on" then
        local heartbeat_map = exporter_obj.heartbeat_map
        for registry_obj, _ in pairs(heartbeat_map) do
            if switcher == consts.MOTAN_SWITCHER_200 then
                registry_obj:available()
            end

            if switcher == consts.MOTAN_SWITCHER_503 then
                registry_obj:unavailable()
            end
        end
    end
end

local function _do_check(exporter_obj)
    for __, switcher in pairs(switcher_set) do
        local switcher_value = switch_shm:get(switcher)
        if switcher_value == nil then
           goto CONTINUE
        end

        ngx.log(ngx.NOTICE, "start check switcher:", switcher, ", switcher_value:", switcher_value)
        switch_check_handle(switcher, switcher_value, exporter_obj)
        reset_switch(switcher)
        ::CONTINUE::
    end
end

function _M:start_check(exporter_obj)
    -- if there is no switch_shm set, then it means no need to check the switchers
    -- the ngx config like: lua_shared_dict motan_switch 20m;
    if switch_shm == nil then
        return
    end
    ngx.log(ngx.NOTICE, "start switch checker.")
    local check_timer = timer:new(true)
    check_timer:tick(check_timer.NO_RES, DEFAULT_CHECK_INTERVAL, _do_check, exporter_obj)
end

return _M
