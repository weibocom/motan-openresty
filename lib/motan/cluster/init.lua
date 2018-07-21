-- Copyright (C) idevz (idevz.org)

local pairs = pairs
local ipairs = ipairs
local assert = assert
local setmetatable = setmetatable
local utils = require "motan.utils"
local consts = require "motan.consts"
local singletons = require "motan.singletons"
local table_insert = table.insert

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M._init_filters(self)
    local cluster_filter, endpoint_filters = self.url:get_filters()
    if utils.is_empty(cluster_filter) then
        self.cluster_filter = self.ext:get_last_cluster_filter()
    else
        self.cluster_filter = cluster_filter
    end
    if not utils.is_empty(endpoint_filters) then
        self.filters = endpoint_filters
    end
end

function _M.init(self)
    self.ha = self.ext:get_ha(self.url)
    self.lb = self.ext:get_lb(self.url)
    self:_init_filters()
    self:_parse_registry()
end

function _M.refresh(self)
    local refers = {}
    for _, registry_refer in pairs(self.registry_refers) do
        for _, ref_url_obj in ipairs(registry_refer) do
            table_insert(refers, ref_url_obj)
        end
    end
    self.refers = refers
    self.lb:on_refresh(refers)
end

local _get_filter_endpoint
_get_filter_endpoint = function(up_opts)
    local _res = {
        _VERSION = "0.0.1"
    }
    local _mt = {__index = _res}
    function _res.new(_res_self, opts)
        local _filter_endpoint = {
            url = opts.url,
            filter = opts.filter,
            caller = opts.caller,
            status_filters = opts.status_filters,
            name = "filter_endpoint"
        }
        return setmetatable(_filter_endpoint, _mt)
    end

    function _res.call(_res_self, req)
        return _res_self.filter:filter(_res_self.caller, req)
    end

    function _res.get_url(_res_self)
        return _res_self.url
    end

    function _res.set_url(_res_self, url)
        _res_self.url = url
    end

    function _res.get_name(_res_self)
        return _res_self.name
    end

    function _res.destroy(_res_self)
    end
    --luacheck:ignore
    function _res.set_proxy(_res_self, proxy)
    end
    --luacheck:ignore
    function _res.set_serialization(_res_self, serialization)
    end

    function _res.is_available(_res_self)
        if not utils.is_empty(_res_self.status_filters) then
            for i = #_res_self.status_filters, 1, -1 do
                local is_available = _res_self.status_filters[i]:is_available()
                if not is_available then
                    return false
                end
            end
        end
        return _res_self.caller:is_available()
    end
    return _res:new(up_opts)
end

function _M._add_filter(self, endpoint)
    local last_filter = self.ext:get_last_endpoint_filter()
    local status_filters = {}
    for _, filter in ipairs(self.filters) do
        local nfilter = filter:new_filter(endpoint:get_url())
        nfilter:set_next(last_filter)
        last_filter = nfilter
        if nfilter["is_available"] ~= nil then
            table_insert(status_filters, nfilter)
        end
    end
    local filter_endpoint =
        _get_filter_endpoint {
        url = endpoint:get_url(),
        filter = last_filter,
        caller = endpoint,
        status_filters = status_filters
    }
    return filter_endpoint
end

function _M._notify(self, registry, ref_url_objs)
    if utils.is_empty(ref_url_objs) then
        return
    end
    local registry_key = registry:get_identity()
    ngx.log(ngx.DEBUG, "==>cluster notify:", registry_key)
    local endpoints = {}
    local endpoints_map = {}
    local reg_referers = self.registry_refers[registry_key]
    if not utils.is_empty(reg_referers) then
        for _, endpoint in ipairs(reg_referers) do
            local key = endpoint:get_url():get_identity()
            endpoints_map[key] = endpoint
        end
    end
    for _, url in ipairs(ref_url_objs) do
        if not utils.is_empty(url) then
            if not utils.is_empty(endpoints_map[url:get_identity()]) then
                endpoints_map[url:get_identity()] = nil
            end
            local ep = self.ext:get_endpoint(url)
            ep = self:_add_filter(ep)
            table_insert(endpoints, ep)
        else
            ngx.log(ngx.ERR, "Cluster notified an empty url\n")
        end
    end
    if #endpoints == 0 then
        if #self.registry_refers > 0 then
            self.registry_refers[registry_key] = nil
        end
    else
        self.registry_refers[registry_key] = endpoints
    end
    self:refresh()
end

function _M.get_identity(self)
    return self.url:get_identity()
end

function _M.call(self, req)
    return self.cluster_filter:filter(self.ha, self.lb, req)
end

function _M._parse_registry(self)
    local registry_keys = self.url.params[consts.MOTAN_REGISTRY_KEY]
    local registry_arr = utils.split(registry_keys, ",")
    for _, registry_key in ipairs(registry_arr) do
        local registry_url_obj =
            assert(singletons.client_regstry[registry_key], "Empty registry config: " .. registry_key)
        local registry = self.ext:get_registry(registry_url_obj)
        assert(registry ~= nil, "_parse_registry got not registry obj")
        registry:subscribe(self.url, self)
    end
end

function _M.new(self, ref_url_obj)
    local ext = singletons.motan_ext
    local cluster = {
        url = ref_url_obj,
        registries = {},
        ha = {},
        lb = {},
        refers = {},
        -- @TODO
        filters = {},
        cluster_filter = {},
        ext = ext,
        registry_refers = {},
        endpoint_map = {},
        available = true,
        closed = false
    }
    return setmetatable(cluster, mt)
end

return _M
