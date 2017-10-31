-- Copyright (C) idevz (idevz.org)


local _M = {}

function _M.ini(lines, name)
    local t = {}
    local section
    for line in lines(name) do
        local s = line:match("^%[([^%]]+)%]$")
        if s then
            section = s
            t[section] = t[section] or {}
            goto CONTINUE
        end
        local key, value = line:match("^(%w+)%s-=%s-(.+)$")
        if key and value then
            if tonumber(value) then value = tonumber(value) end
            if value == "true" then value = true end
            if value == "false" then value = false end
            t[section][key] = value
        end
        ::CONTINUE::
    end
    return t
end

return _M
