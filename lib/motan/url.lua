-- Copyright (C) idevz (idevz.org)

local utils = require "motan.utils"
local consts = require "motan.consts"
local singletons = require "motan.singletons"
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert
local tab_sort = table.sort

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M.new(self, opts)
    local url = {}
    local opt_type = type(opts)
    if opt_type == "table" and not utils.is_empty(opts) then
        url = {
            protocol = opts.protocol or "",
            host = opts.host or singletons.var.LOCAL_IP,
            port = opts.port or 0,
            path = opts.path or "",
            group = opts.group or "",
            params = opts.params or {}
        }
        local check_arr = {
            "protocol",
            "host",
            "port",
            "path",
            "group",
            "params"
        }
        for k, v in pairs(opts) do
            if not utils.is_in_table(k, check_arr) then
                url.params[k] = v
            end
        end
    -- elseif opt_type == "string" then
    -- @TODO
    end
    return setmetatable(url, mt)
end

function _M.get_addr(self)
    local addr_info = {
        self.protocol,
        consts.PROTOCOL_SEPARATOR,
        self.host,
        consts.COLON_SEPARATOR,
        self.port,
        consts.PATH_SEPARATOR
    }
    return tab_concat(addr_info)
end

function _M.copy(self)
    local url = {}
    local params = {}
    for k, v in pairs(self.params) do
        params[k] = v
    end
    url.protocol, url.host, url.port, url.path, url.group, url.params =
        self.protocol,
        self.host,
        self.port,
        self.path,
        self.group,
        params
    return self:new(url)
end

function _M.get_identity(self)
    local url_info = self:get_urlinfo()
    return tab_concat(url_info)
end

function _M.get_urlinfo(self, with_params_str)
    local url_info = {
        self.protocol,
        consts.PROTOCOL_SEPARATOR,
        self.host,
        consts.COLON_SEPARATOR,
        self.port,
        consts.PATH_SEPARATOR,
        self.path,
        consts.QMARK_SEPARATOR,
        "group=",
        self.group
    }
    if with_params_str then
        local params_arr = {}
        if self.params ~= nil then
            for k, v in pairs(self.params) do
                tab_insert(params_arr, consts.QUERY_PARAM_SEPARATOR)
                tab_insert(params_arr, k)
                tab_insert(params_arr, consts.EQUAL_SIGN_SEPERATOR)
                tab_insert(params_arr, v)
            end
        end
        tab_insert(url_info, tab_concat(params_arr))
    end
    return url_info
end

function _M.to_extinfo(self)
    return tab_concat(self:get_urlinfo(true))
end

function _M.get_filters(self)
    local filter_str
    if self.params[consts.MOTAN_FILTER_KEY] ~= nil then
        filter_str = self.params[consts.MOTAN_FILTER_KEY]
    else
        return nil, nil
    end
    local filter_keys
    filter_keys = assert(utils.split(filter_str, consts.COMMA_SEPARATOR), "Error parse filter conf.")
    local cluster_filters = {}
    local endpoint_filters = {}
    local cluster_filter = {}
    if not utils.is_empty(filter_keys) then
        for _, filter_key in ipairs(filter_keys) do
            local filter = singletons.motan_ext:get_filter(filter_key)
            if filter:get_type() == consts.MOTAN_FILTER_TYPE_CLUSTER then
                local nfilter = filter:new_filter(self)
                tab_insert(cluster_filters, nfilter)
            else
                tab_insert(endpoint_filters, filter)
            end
        end
        if #cluster_filters > 0 then
            tab_sort(
                cluster_filters,
                function(filter1, filter2)
                    return filter1:get_index() > filter2:get_index()
                end
            )
            local last_cluster_filter
            last_cluster_filter = singletons.motan_ext:get_last_cluster_filter()
            for _, filter in ipairs(cluster_filters) do
                filter:set_next(last_cluster_filter)
                last_cluster_filter = filter
            end
            cluster_filter = last_cluster_filter
        end
        if #endpoint_filters > 0 then
            tab_sort(
                endpoint_filters,
                function(filter1, filter2)
                    return filter1:get_index() > filter2:get_index()
                end
            )
        end
        return cluster_filter, endpoint_filters
    end
    return nil, nil
end

return _M
