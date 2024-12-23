function trace (event, line)
    local s = debug.getinfo(2).short_src
    print(s .. ":" .. line)
end

debug.sethook(trace, "l")

local a = 10;
local b = 10;
print(a + b)

debug.sethook()
