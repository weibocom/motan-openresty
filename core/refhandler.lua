-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local url = require "motan.url"
local setmetatable = setmetatable

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

local _build_url
_build_url = function(conf_info, conf_section)
    if conf_section == "service_urls" then
        if not conf_info.path 
        or not conf_info.protocol
        -- @TODO host is didn't need be configed
        or not conf_info.host
        or not conf_info.port then
            return nil, "_build_url Err: service need host, port, path and protocol info."
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

function _M.get_section_map(self, conf_section)
    local service_map = {}
    local service_url_obj = {}
    for k, conf_info in pairs(self.motan_conf[conf_section]) do
        local service_url_obj, err = _build_url(conf_info, conf_section)
        if not service_url_obj then
            ngx.log(ngx.ERR, err)
            goto continue
        end
        service_map[k] = service_url_obj
        -- ngx.log(ngx.ERR, "\n-------" .. conf_section .. "--------" .. k .. "\n")
        -- ngx.log(ngx.ERR, "\n---------------" .. sprint_r(service_url_obj) .. "\n")
        ::continue::
    end
    return service_map
end

function _M.new(self, gctx_obj)
    local gctx_obj = assert(gctx_obj, "gctx is nil.")
    local service = {
        motan_conf = gctx_obj,
	}
    return setmetatable(service, mt)
end

return _M
