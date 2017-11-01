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
local share_motan = ngx.shared.motan_client
local json = require 'cjson'
local resty_lrucache_ffi = require 'resty.lrucache.pureffi'

local singletons = require "motan.singletons"
local motan_consul = require "motan.registry.consul"
local url = require "motan.url"
local consts = require "motan.consts"
local cluster = require "motan.cluster"
local client = require "motan.client.handler"
local lrucache = assert(resty_lrucache_ffi.new(consts.MOTAN_LRU_MAX_REFERERS))

local Motan = {}

function Motan.init(path, sys_conf_files)
    local gctx = require "motan.core.gctx"
    local gctx_obj = assert(gctx:new(path, sys_conf_files), "Error to init gctx Conf.")
    local refhandler = require "motan.core.refhandler"
    singletons.config = gctx_obj
    local refhd_obj = refhandler:new(gctx_obj)
    local referer_map = refhd_obj:get_section_map("referer_urls")
    -- @TODO lrucache items number
    lrucache:set(consts.MOTAN_LUA_REFERERS_SHARE_KEY, referer_map)
    ngx.log(ngx.ERR, "\n----ccccccccddddd--referer_map---------" .. sprint_r(referer_map) .. "\n")
end

function Motan.init_worker()
    ngx.log(ngx.ERR, "\n----ccccccccddddd--referervvvv_map---------" .. sprint_r("referer_map") .. "\n")
    local referer_map = lrucache:get(consts.MOTAN_LUA_REFERERS_SHARE_KEY)
    local client_map =  {}
    -- local client_map = cluster_map = {}
    for k, ref_url_obj in pairs(referer_map) do
        local cluster_obj = {}
        cluster_obj = cluster:new{url=ref_url_obj}
        client_map[k] = client:new{
            url = ref_url_obj,
            cluster = cluster_obj,
        }
    end
    ngx.log(ngx.ERR, "\n----client_map-----------" .. sprint_r(client_map) .. "\n")
    lrucache:set(consts.MOTAN_LUA_CLIENTS_LRU_KEY, client_map)
end

function Motan.access()
    local ctx = ngx.ctx
    local referer_map = lrucache:get(consts.MOTAN_LUA_REFERERS_SHARE_KEY)
    ctx.referer_map = referer_map
    -- body
end

function Motan.content()
    local ctx = ngx.ctx
    -- local client_map = lrucache:get(consts.MOTAN_LUA_CLIENTS_LRU_KEY)
    -- local client = client_map['rpc_zk_test']
    -- client:call()
    print_r(ctx.client)
end

return Motan