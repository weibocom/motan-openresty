print("hello world")

function print_table(node)
    -- to make output beautiful
    local function tab(amt)
        local str = ""
        for i = 1, amt do
            str = str .. "\t"
        end
        return str
    end

    local cache, stack, output = {}, {}, {}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k, v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k, v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str, "}", output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str, "\n", output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output, output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "[" .. tostring(k) .. "]"
                else
                    key = "['" .. tostring(k) .. "']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. tab(depth) .. key .. " = " .. tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. tab(depth) .. key .. " = {\n"
                    table.insert(stack, node)
                    table.insert(stack, v)
                    cache[node] = cur_index + 1
                    break
                else
                    output_str = output_str .. tab(depth) .. key .. " = '" .. tostring(v) .. "'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth - 1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth - 1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. tab(depth - 1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output, output_str)
    output_str = table.concat(output)

    print(output_str)
end

local cmotan = require("cmotan")
print(cmotan.version())
local v = {
    1.1, -- float
    1237981, -- int
    2123123,
    {},
    true, -- bool
    { a = "b", c = "d", e = 4 }, -- map<object, object>
    { "what", "is", "wrong" }, -- string[]
    "hello world",
    { a = { "this", "is", "a", "test" }, b = { "this", "is", "a", "test" } }, -- map<string, string[]>
    { { aa = "bb", aaa = "bb" }, { cc = "dd", ccc = "dd" }, { ee = "ff", eee = "ff" }, { gg = "hh", ggg = "hh" } } -- map<string,sring>[]
};
v[4][1.11] = "1"

print_table({ cmotan.simple_serialize(v) })
print_table(cmotan.simple_deserialize(cmotan.simple_serialize(v)))

local wrong_buf = "1" .. cmotan.simple_serialize(v)
local _, err = pcall(cmotan.simple_deserialize, wrong_buf)
print(err)

local max_test_time = 100000
local buf = cmotan.simple_serialize(v)
for i = 1, max_test_time do
    cmotan.simple_serialize(v)
end

for i = 1, max_test_time do
    cmotan.simple_deserialize(buf)
end
