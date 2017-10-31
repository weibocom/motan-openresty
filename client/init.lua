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
    lrucache:set(consts.MOTAN_LUA_SERVICES_SHARE_KEY, referer_map)
end

function Motan.init_worker()
    local referer_map = lrucache:get(consts.MOTAN_LUA_SERVICES_SHARE_KEY)
end

function Motan.access()
    local ctx = ngx.ctx
    local referer_map = lrucache:get(consts.MOTAN_LUA_SERVICES_SHARE_KEY)
    ctx.referer_map = referer_map
    -- body
end

function Motan.content()
    local ctx = ngx.ctx
    print_r(ctx.referer_map)
end

return Motan