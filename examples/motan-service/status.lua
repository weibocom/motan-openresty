-- Copyright (C) idevz (idevz.org)


local setmetatable = setmetatable
local share_motan = ngx.shared.motan
-- local utils = require "motan.utils"
local singletons = require "motan.singletons"
local serialize = require "motan.serialize.simple"

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

-- @TODO add metadata to service_instance when new
function _M.new(self, opts)
    local status = {}
    return setmetatable(status, mt)
end

function _M.show_batch(self, opts)
	local idevz = share_motan:get("idevz") or 0
	share_motan:set("idevz", idevz + 1)
	local num = share_motan:get("idevz")

    local client_map = singletons.client_map
    local client = client_map["rpc_test_java"]
    local rpc_res_tmp = client:hello("<-----Motan")
    local rpc_res = serialize.deserialize(rpc_res_tmp.body)


	if type(opts) == "table" then
		if not opts.name then
		    return "--> Motan" .. "->not name----->\n" .. sprint_r(opts) .. num
		else
		    return {
		        openresty = "--> Motan" .. "-" .. opts.name .. ngx.now(),
		        Rpc_call_test = "Rpc_call_test -->: " .. sprint_r(rpc_res) .. singletons.var.LOCAL_IP
		    }
		end
	else
		local x = {}
		table.insert(x, "a")
		table.insert(x, "b")
		table.insert(x, "c")
		return {ok = "ok." .. table.concat(x)}
	end
end

return _M
