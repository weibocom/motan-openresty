-- Copyright (C) idevz (idevz.org)


local url = require "motan.url"
local utils = require "motan.utils"
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

local _parse_conf
_parse_conf = function(sys_conf)
    local path = sys_conf.SERVICE_PATH
    local config_handle_obj = config_handle:new{ctype = "ini", cpath = path}
    local conf_files = {}
    conf_files.MOTAN_CLIENT_CONF_FILE = sys_conf.MOTAN_CLIENT_CONF_FILE or nil
    conf_files.MOTAN_SERVER_CONF_FILE = sys_conf.MOTAN_SERVER_CONF_FILE or nil

    local conf_res = {}
    if not utils.is_empty(conf_files) then
        for _,v in pairs(conf_files) do
            conf_res[v] = config_handle_obj:get('sys/' .. v)
        end
        return conf_res
    end
    return nil
end

local _build_url
_build_url = function(conf_info, conf_section)
    if conf_section == "service_urls" then
        if not conf_info.path 
        or not conf_info.protocol
        -- @TODO host is didn't need be configed
        or not conf_info.host
        or not conf_info.port then
            return nil, "_build_url Err: service need host, port, path and protocol info.\n" .. sprint_r(conf_info)
        end
    end
    local service_url = url:new(conf_info)

    -- @TODO pcall(require or require per request
    -- local ok, service_lib_or_error = pcall(require, service_path)
    -- if not ok then
    --     return nil, "Pcall require err:" .. service_lib_or_error
    -- end
    if conf_section == "service_urls" then
        -- @TODO remove MOTAN_LUA_SERVICE_PERFIX
        local ss = service_url.path
        local s,e = string.find(ss, consts.MOTAN_LUA_SERVICE_PERFIX)
        if not s then
            return nil, "_build_url Err: service perfix conf err"
        end
        local service_path = consts.MOTAN_LUA_SERVICE_PATH .. string.sub(ss, e + 1)
        service_url.params[consts.MOTAN_LUA_SERVICE_PACKAGE] = service_path
        service_url.params["nodeType"] = consts.MOTAN_NODETYPE_SERVICE
    elseif conf_section == "referer_urls" then
        service_url.params["nodeType"] = consts.MOTAN_NODETYPE_REFERER
    end
    return service_url
end

local _get_section
_get_section = function(self, conf_file)
    local tmp_section_urls = {}
    local section_urls = {}
    local registry_urls = {}
    local conf_section = ""
    if conf_file == self.conf_set.MOTAN_SERVER_CONF_FILE then
        local server_conf = assert(self.conf_arr[conf_file], "Get server config arr err, Check if have this file: " .. conf_file)
        registry_urls = _parse_conf_by_key(server_conf,consts.MOTAN_REGISTRY_PREFIX)
        local service_urls = _parse_conf_by_key(server_conf,consts.MOTAN_SERVICES_PREFIX)
        local basic_services = _parse_conf_by_key(server_conf,consts.MOTAN_BASIC_SERVICES_PREFIX)
        tmp_section_urls = _parse_basic(service_urls, basic_services, consts.MOTAN_BASIC_REF_KEY)
        -- @TODO rm conf_section
        conf_section = "service_urls"
    elseif conf_file == self.conf_set.MOTAN_CLIENT_CONF_FILE then
        local client_conf = assert(self.conf_arr[conf_file], "Get client config arr err, Check if have this file: " .. conf_file)
        registry_urls = _parse_conf_by_key(client_conf,consts.MOTAN_REGISTRY_PREFIX)
        local referer_urls = _parse_conf_by_key(client_conf,consts.MOTAN_REFS_PREFIX)
        local basic_refs = _parse_conf_by_key(client_conf,consts.MOTAN_BASIC_REFS_PREFIX)
        tmp_section_urls = _parse_basic(referer_urls, basic_refs, consts.MOTAN_BASIC_REF_KEY)
        conf_section = "referer_urls"
    end
    local section_urls_obj = {}
    for k, conf_info in pairs(tmp_section_urls) do
        local section_urls_obj, err = _build_url(conf_info, conf_section)
        if not section_urls_obj then
            ngx.log(ngx.ERR, err)
            goto continue
        end
        section_urls[k] = section_urls_obj
        ::continue::
    end
    return section_urls, registry_urls
end

function _M.new(self, sys_conf)
    local conf_arr = assert(_parse_conf(sys_conf), "Parse conf Err: cloudn't find any config files.")
    local sysconf = {
        conf_set = sys_conf,
        conf_arr = conf_arr,
    }
    return setmetatable(sysconf, mt)
end

function _M.get_server_conf(self)
    return _get_section(self, self.conf_set.MOTAN_SERVER_CONF_FILE)
end

function _M.get_client_conf(self)
    return _get_section(self, self.conf_set.MOTAN_CLIENT_CONF_FILE)
end

return _M
