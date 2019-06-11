-- Copyright (C) idevz (idevz.org)

-- local utils = require 'motan.utils'
-- local client_map = setmetatable({raw_client_map={}}, {
--     __newindex = function(self, key, value)
--         self.raw_client_map[key] = value
--     end,
--     __index = function(self, key)
--         local rs = self.raw_client_map[key]
--         local res = utils.deepcopy(rs)
--         return res
--     end
-- })

local _M = {
    _VERSION = "0.1.0",
    is_dev = false,
    config = {},
    var = {},
    motan_ext = {},
    referer_map = {},
    client_map = {},
    client_registry = {},
    service_map = {},
    server_registry = {}
}

return _M
