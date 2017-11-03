-- Copyright (C) idevz (idevz.org)


local helpers = require "motan.utils"

function sprint_r( ... )
    return helpers.sprint_r(...)
end

function lprint_r( ... )
    local rs = sprint_r(...)
    print(rs)
end

function print_r( ... )
    local rs = sprint_r(...)
    ngx.say(rs)
end

local assert = assert

local consts = require "motan.consts"
local client = require "motan.client.handler"
local singletons = require "motan.singletons"

local Motan = {}

function Motan.init(sys_conf)
    local conf = require "motan.core.sysconf"
    local conf_obj = conf:new(sys_conf)
    singletons.config = conf_obj
    local referer_map, client_regstry = conf_obj:get_client_conf()
    singletons.referer_map = referer_map
    singletons.client_regstry = client_regstry
end

function Motan.init_worker()
    local cluster = require "motan.cluster"
    local referer_map = singletons.referer_map
    local client_map =  {}
    for k, ref_url_obj in pairs(referer_map) do
        local cluster_obj = {}
        local registry_key = ref_url_obj.params[consts.MOTAN_REGISTRY_KEY]
        local registry_info = assert(singletons.client_regstry[registry_key]
            , "Empty registry config: " .. registry_key)
        cluster_obj = cluster:new{
            url=ref_url_obj,
            registry_info = registry_info,
        }
        client_map[k] = client:new{
            url = ref_url_obj,
            cluster = cluster_obj,
        }
    end
    singletons.client_map = client_map
end

function Motan.access()
    -- body
end

function Motan.content()
    local serialize = require "motan.serialize.simple"
    local client_map = singletons.client_map
    local client = client_map["rpc_test"]
    local res = client:show_batch({name="idevz"})
    print_r("<pre/>------------")
    print_r(serialize.deserialize(res.body))
    local client2 = client_map["rpc_test_java"]
    local res2 = client2:hello("<-----Motan")
    print_r(serialize.deserialize(res2.body))
end

return Motan