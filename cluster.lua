-- Copyright (C) idevz (idevz.org)


local utils = require "motan.utils"
local singletons = require "motan.singletons"
local endpoint = require "motan.endpoint.motan"
local motan_consul = require "motan.registry.consul"
local setmetatable = setmetatable

local is_empty = function(t)
    return _G.next(t) == nil
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M._init(self)
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
    local c_obj = self.ext:get_registry(self.registry_url_obj)
    c_obj:subscribe(self.url, self)
    -- local gctx_obj = gctx:new()
    -- split(registries_conf,",")
    -- local registry_conf = gctx_obj.registry_urls[registries_conf]
    -- local registry = self.ext_factory.get_regisrty()
    -- registry:subscribe(self.url, _notify)
    -- urls = registry:discover(self.url)
    -- self:_notify(registry_url, urls)
    -- ngx.log(ngx.ERR, "\n---------------" .. sprint_r(registry_url_obj) .. "\n")
end

function _M.new(self, opts)
    local self = {
        url = opts.url,
        registry_url_obj = opts.registry_url_obj,
        registries = {},
        ha = {},
        lb = {},
        refers = {},
        -- @TODO
        filters = {},
        cluster_filters = {},
        ext = singletons.motan_ext,
        registry_refers = {},
        available = ture,
        endpoint_map = {},
        closed = false,
    }
    setmetatable(self, mt)
    self:_init()
    return self
end

return _M
