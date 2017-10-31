-- Copyright (C) idevz (idevz.org)


local consts = require "motan.consts"
local null = ngx.null
local escape_uri = ngx.escape_uri
local setmetatable = setmetatable
local tab_concat = table.concat
local tab_insert = table.insert
local utils = require "motan.utils"
local simple = require "motan.serialize.simple"

local _M = {
    _VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self, opts)
    local msg = {
	    header = opts.header or {},
	    metadata = opts.metadata or {},
	    body = opts.body or {},
	}
    return setmetatable(msg, mt)
end


function _M.get_header(self)
    return self.header
end

function _M.get_metadata(self)
    return self.metadata
end

function _M.get_body(self)
    return self.body
end

function _M.encode(self)
    local buffer = self.header:pack_header()
    if not self.metadata['M_p'] or not self.metadata['M_m'] then
    	if not self.header:is_heartbeat() then
            -- error('None Service Or Method get')
        end
    end
    local mt = {}
    local mt_index = 1
    for k,v in pairs(self.metadata) do
    	if type(v) == "table" then
    		goto continue
    	end
        mt[mt_index] = k .. "\n" .. v
        mt_index = mt_index + 1
        ::continue::
    end
    -- @TODO lua tcp pack
    mt_str = tab_concat(mt, "\n")
    buffer = buffer .. utils.msb_numbertobytes(#mt_str, 4)
    buffer = buffer .. mt_str
    buffer = buffer .. utils.msb_numbertobytes(#self.body, 4)
    buffer = buffer .. self.body

    return buffer
end

return _M
