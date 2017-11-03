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

local ngx = ngx
local assert = assert
local json = require "cjson"

local singletons = require "motan.singletons"
local motan_consul = require "motan.registry.consul"
local url = require "motan.url"
local consts = require "motan.consts"
local cluster = require "motan.cluster"
local client = require "motan.client.handler"

local Motan = {}

function Motan.init(path, sys_conf_files)
    local gctx = require "motan.core.gctx"
    local gctx_obj = assert(gctx:new(path, sys_conf_files), "Error to init gctx Conf.")
    local refhandler = require "motan.core.refhandler"
    singletons.config = gctx_obj
    local refhd_obj = refhandler:new(gctx_obj)
    local referer_map = refhd_obj:get_section_map("referer_urls")
    singletons.referer_map = referer_map
end

function Motan.init_worker()
    local referer_map = singletons.referer_map
    local client_map =  {}
    for k, ref_url_obj in pairs(referer_map) do
        local cluster_obj = {}
        local registry_key = ref_url_obj.params[consts.MOTAN_REGISTRY_KEY]
        local registry_info = assert(singletons.config.registry_urls[registry_key], "Empty registry config.")
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