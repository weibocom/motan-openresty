-- Copyright (C) idevz (idevz.org)


local client_t = require "resty.vintage.client"

local DEFAULT_TIMEOUT = 60*1000 -- 60s default timeout
local DEFAULT_HEART_INTERVAL  = 5

local _M = {
    _VERSION = '0.0.1'
}

local mt = {__index = _M}

function _M:new(shm, addr, timeout, heart_interval)
    local addr = addr or nil
    assert(addr ~= nil, "Vintage Registry addr must not be nil.")

	local shm = shm
    assert(shm ~= nil, "Vintage need a share dict to store nodes.")

    local timeout = timeout or DEFAULT_TIMEOUT
    local heart_interval = heart_interval or DEFAULT_HEART_INTERVAL
    
    local api_client = client_t:new{
        addr = addr,
        shm = shm,
        timeout = timeout,
        heart_interval = heart_interval,
    }
    local naming_service_t = {
        api_client = api_client
    }
    return setmetatable(naming_service_t, mt)
end

function _M:set_snapshot_dir(d)
end

function _M:enable_snapshot(b)
end

function _M:start()
    return self.api_client:start()
end

function _M:stop()
    return self.api_client:stop()
end

function _M:lookup(service_id, cluster_id)
    return self.api_client:naming_service_lookup(service_id, cluster_id)
end

function _M:register(service_id, cluster_id, node, ext_info)
    ngx.timer.at(0, function(premature, self, service_id, cluster_id, node, ext_info)
        if not premature then
            local from = ngx.re.find(cluster_id, [[/referer]], "jo")
            if not from then
                self.api_client:heartbeat(service_id, cluster_id, node)
            end
            local ok, err = self.api_client:register_node(
                service_id, cluster_id, node, ext_info)
            if err ~= nil then
                ngx.log(ngx.ERR, "Vintage registry err: ", sprint_r(err)
                , ", service_id:", service_id
                , ", cluster_id:", cluster_id
                , ", node:", node)
            else
                ngx.log(ngx.NOTICE, "Vintage registry sucess: "
                , ", service_id:", service_id
                , ", cluster_id:", cluster_id
                , ", node:", node)
            end
        end
    end, self, service_id, cluster_id, node, ext_info)
end

function _M:unregister(service_id, cluster_id, node)
    self.api_client:unheart_beat(service_id, cluster_id, node)
    return self.api_client:unregister_node(service_id, cluster_id, node)
end

function _M:unregister_all()
end

function _M:watch(service_name, cluster_name)
    return self.api_client:naming_service_watch(service_name, cluster_name)
end

function _M:unwatch(naming_service_wath_ch)
    return self.api_client:naming_service_unwatch(service_name, cluster_name)
end

function _M:unwatch_all(service_name)
end

function _M:clear_watch()
end

function _M:set_node_excise_strategy(strategy)
end

return _M