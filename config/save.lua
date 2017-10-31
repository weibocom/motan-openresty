-- Copyright (C) idevz (idevz.org)


local _M = {}

function _M.ini(write, name, t)
    local contents = ""
    for section, s in pairs(t) do
        contents = contents .. ("[%s]\n"):format(section)
        for key, value in pairs(s) do
            contents = contents .. ("%s=%s\n"):format(key, tostring(value))
        end
        contents = contents .. "\n"
    end
    write(name, contents)
end

return _M
