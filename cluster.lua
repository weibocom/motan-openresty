-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local gctx = require "motan.core.gctx"
local null = ngx.null
local escape_uri = ngx.escape_uri
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert

local is_empty = function(t)
    return _G.next(t) == nil
end

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M._init(self)
    if is_empty(self.ext_factory) then
        -- error("xxx")
    end
    -- self.ha = self.ext_factory.get_ha(self.url)
    -- self.lb = self.ext_factory.get_lb(self.url)
    self:_parse_registry()
end

function _M._notify()
    -- body
end

function _M._parse_registry(self)
    local registries_conf = self.url.params[consts.MOTAN_REGISTRY_KEY]
    local gctx_obj = gctx:new()
    -- split(registries_conf,",")
    local registry_conf = gctx_obj.registry_urls[registries_conf]
    -- local registry = self.ext_factory.get_regisrty()
    -- registry:subscribe(self.url, _notify)
    -- urls = registry:discover(self.url)
    -- self:_notify(registry_url, urls)
    print_r(registry_conf)
end

function _M.new(self, url)
    local self = {
        url = url,
        registries = {},
        ha = {},
        lb = {},
        refers = {},
        -- @TODO
        filters = {},
        cluster_filters = {},
        ext_factory = {},
        registry_refers = {},
        available = ture,
        closed = false,
    }
    setmetatable(self, mt)
    self:_init()
    return self
end

return _M
