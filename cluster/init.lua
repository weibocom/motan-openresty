-- Copyright (C) idevz (idevz.org)


local assert = assert
local setmetatable = setmetatable
local utils = require "motan.utils"
local consts = require "motan.consts"
local singletons = require "motan.singletons"
local endpoint = require "motan.endpoint.motan"
local motan_consul = require "motan.registry.consul"


local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M._init_filters(self)
    local filter_keys = {}
    filter_keys = assert(
        utils.split(self.url.params[consts.MOTAN_FILTER_KEY], consts.COMMA_SEPARATOR)
        , "Error parse filter conf."
        )
    local cluster_filters = {}
    local endpoint_filters = {}
    if not utils.is_empty(filter_keys) then
        for _, filter_key in ipairs(filter_keys) do
            local filter = self.ext:get_filter(filter_key)
            if filter:get_type() == consts.MOTAN_FILTER_TYPE_CLUSTER then
                table.insert(cluster_filters, filter)
            else
                table.insert(endpoint_filters, filter)
            end
        end
        if #cluster_filters > 0 then
            table.sort(cluster_filters, function(filter1, filter2)
                return filter1:get_index() > filter2:get_index()
            end)
            local last_cluster_filter = {}
            for _, filter in ipairs(cluster_filters) do
                filter:set_next(last_cluster_filter)
                last_cluster_filter = filter
            end
            cluster_filters = last_cluster_filter
        end
        if #endpoint_filters > 0 then
            table.sort(endpoint_filters, function(filter1, filter2)
                return filter1:get_index() > filter2:get_index()
            end)
        end
        self.cluster_filters = cluster_filters
        self.filters = endpoint_filters
    end
    ngx.log(ngx.ERR, "------------------->\n", sprint_r(self.filters))
end

function _M._init(self)
    self.ha = self.ext:get_ha(self.url)
    self.lb = self.ext:get_lb(self.url)
    self:_init_filters()
    self:_parse_registry()
end

function _M.refresh(self)
    local refers = {}
    for k, ref_url_obj in pairs(self.registry_refers) do
        table.insert(refers, ref_url_obj)
    end
    self.refers = refers
    -- self.lb.onfresh
end

function _M._notify(self, registry, ref_url_objs)
    if not utils.is_empty(ref_url_objs) then
        for _, url in pairs(ref_url_objs) do
            local key = registry:get_identity()
            self.registry_refers[key] = url
        end
        self:refresh()
    end
end

function _M.call(self, req)
    local ep = self.ext:get_endpoint(self.refers[1])
    if not utils.is_empty(ep) then
        return ep:call(req)
    end
end

function _M._parse_registry(self)
    -- @TODO support multi regstry at the same time
    local registry_key = self.url.params[consts.MOTAN_REGISTRY_KEY]
    local registry_url_obj = assert(singletons.client_regstry[registry_key]
        , "Empty registry config: " .. registry_key)
    local registry = self.ext:get_registry(registry_url_obj)
    registry:subscribe(self.url, self)
end

function _M.new(self, ref_url_obj)
    local ext = singletons.motan_ext
    local self = {
        url = ref_url_obj,
        registries = {},
        ha = {},
        lb = {},
        refers = {},
        -- @TODO
        filters = {},
        cluster_filters = {},
        ext = ext,
        registry_refers = {},
        endpoint_map = {},
        available = ture,
        closed = false
    }
    setmetatable(self, mt)
    self:_init()
    return self
end

return _M
