-- Copyright (C) idevz (idevz.org)

local _M = {
    _VERSION = "0.0.1"
}

local mt = {__index = _M}

function _M.new(self, opts)
    local request = {
        request_id = opts.request_id or nil,
        service_name = opts.service_name or nil,
        method = opts.method or nil,
        method_desc = opts.method_desc or nil,
        arguments = opts.arguments or nil,
        args_num = opts.args_num or 0,
        attachment = opts.attachment or {}
    }
    return setmetatable(request, mt)
end

function _M.get_attachment(self, key)
    return self.attachment[key]
end

function _M.set_attachment(self, key, value)
    self.attachment[key] = value
end

function _M.get_service_name(self)
    return self.service_name
end

function _M.get_method(self)
    return self.method
end

function _M.get_method_desc(self)
    return self.method_desc
end

function _M.get_arguments(self)
    return self.arguments
end

function _M.get_request_id(self)
    return self.request_id
end

function _M.set_arguments(self, arguments)
    self.arguments = arguments
end

function _M.get_attachments(self)
    return self.attachment
end

-- function _M.get_rpc_context(self, canCreate bool)
-- end

-- function _M.process_deserializable(self, toTypes)
-- end

return _M
