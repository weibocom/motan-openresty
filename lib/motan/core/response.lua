-- Copyright (C) idevz (idevz.org)

local _M = {
    _VERSION = "0.1.0"
}

local mt = {__index = _M}

function _M.new(self, opts)
    local response = {
        request_id = opts.request_id or nil,
        value = opts.value or nil,
        exception = opts.exception or nil,
        process_time = opts.process_time or nil,
        attachments = opts.attachments or {},
        reused_times = opts.reused_times or nil
        -- RpcContext = opts.RpcContext or nil,
    }
    return setmetatable(response, mt)
end

function _M.get_attachment(self, key)
    return self.attachments[key] or nil
end

function _M.set_attachment(self, key, value)
    self.attachments[key] = value
end

function _M.get_value(self)
    return self.value
end

function _M.get_exception(self)
    return self.exception
end

function _M.get_request_id(self)
    return self.request_id
end

function _M.get_process_time(self)
    return self.process_time
end

function _M.get_attachments(self)
    return self.attachments
end

-- function _M.getRpcContext(self, canCreate)
-- end

function _M.set_process_time(self, time)
    self.process_time = time
end

-- function _M.grocessDeserializable(self, toType)
-- end

function _M.get_reused_times(self)
    return self.reused_times
end

function _M.set_reused_times(self, times)
    self.reused_times = times
end

return _M
