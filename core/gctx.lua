-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local config_handle = require "motan.config.handle"
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

local _parse_conf_by_key
_parse_conf_by_key = function(g_conf, prefix)
    local key_start, key_end = 0,0
    local rs_key = ""
    local rs = {}
    for k,v in pairs(g_conf) do
        key_start, key_end = string.find(k, prefix)
        if key_start then
            rs_key = string.sub(k, key_end + 1)
            rs[rs_key] = v
        else
            goto continue
        end
        ::continue::
    end
    return rs
end

local _parse_basic
_parse_basic = function(info, basic_info, basic_key)
    local basic_ref_key = ""
    local build_res = {}
    for k,ref_info in pairs(info) do
        basic_ref_key = ref_info[basic_key]
        local basic_ref = basic_info[basic_ref_key]
        local rs = {}
        if basic_ref ~= nil then
            for bk,bv in pairs(basic_ref) do
                rs[bk] = bv
            end
            for ref_k,v in pairs(ref_info) do
                rs[ref_k] = v
            end
            build_res[k] = rs
        else
            build_res[k] = ref_info
        end
    end
    return build_res
end

local service_conf
service_conf = function(service_path, sys_conf_files)
    local config_handle_obj = config_handle:new{ctype = "ini", cpath = service_path}
    local sys_conf = {}
    for _,v in ipairs(sys_conf_files) do
        sys_conf[v] = config_handle_obj:get('sys/' .. v)
    end
    return sys_conf
end

function _M.new(self, service_path, sys_conf_files)
    local sys_conf = service_conf(service_path, sys_conf_files)
    local g_conf = sys_conf[consts.MOTAN_GCTX_CONF_KEY]
    local gctx = {
        config = g_conf or {},
        registry_urls = _parse_conf_by_key(g_conf,consts.MOTAN_REGISTRY_PREFIX) or {},
        referer_urls = _parse_conf_by_key(g_conf,consts.MOTAN_REFS_PREFIX) or {},
        basic_refs = _parse_conf_by_key(g_conf,consts.MOTAN_BASIC_REFS_PREFIX) or {},
        service_urls = _parse_conf_by_key(g_conf,consts.MOTAN_SERVICES_PREFIX) or {},
        basic_services = _parse_conf_by_key(g_conf,consts.MOTAN_BASIC_SERVICES_PREFIX) or {},
    }
    gctx.referer_urls = _parse_basic(gctx.referer_urls, gctx.basic_refs, consts.MOTAN_BASIC_REF_KEY)
    gctx.service_urls = _parse_basic(gctx.service_urls, gctx.basic_services, consts.MOTAN_BASIC_REF_KEY)
    return setmetatable(gctx, mt)
end


return _M
