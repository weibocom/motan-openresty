-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local utils = require "motan.utils"
local endpoint = require "motan.endpoint.motan"
local motan_consul = require "motan.registry.consul"
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
    self:_parse_registry()
end

-- @TODO registry url
function _M._notify(self, registry, urls)
    if not utils.is_empty(urls) then
        for _, url in pairs(urls) do
            local ep = endpoint:new{
                url = url,
            }
            local key = registry:get_identity()
            self.endpoint_map[1] = ep
        end
    end
end

function _M.call(self, req)
    local ep = self.endpoint_map[1]
    if not utils.is_empty(ep) then
        return ep:call(req)
    end
end


local _get_consul_obj
_get_consul_obj = function(registry_info)
    return motan_consul:new{
        host = registry_info.host,
        port = registry_info.port,
    }
end

function _M._parse_registry(self)
    local c_obj = _get_consul_obj(self.registry_info)
    c_obj:subscribe(self.url, self)
    -- local gctx_obj = gctx:new()
    -- split(registries_conf,",")
    -- local registry_conf = gctx_obj.registry_urls[registries_conf]
    -- local registry = self.ext_factory.get_regisrty()
    -- registry:subscribe(self.url, _notify)
    -- urls = registry:discover(self.url)
    -- self:_notify(registry_url, urls)
    -- ngx.log(ngx.ERR, "\n---------------" .. sprint_r(registry_info) .. "\n")
end

function _M.new(self, opts)
    local self = {
        url = opts.url,
        registry_info = opts.registry_info,
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
        endpoint_map = {},
        closed = false,
    }
    setmetatable(self, mt)
    self:_init()
    return self
end

return _M
