local t = {}
local inp = io.input()      -- 输入流
local out = io.output()     -- 输出流


for line in inp:lines() do
    t[#t + 1] = line
end

for i = #t, 1, -1 do
    out:write(t[i], "\n")
end
