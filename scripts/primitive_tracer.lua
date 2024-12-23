debug.sethook(print, "l")

local a = 10;
local b = 10;
print(a + b)

debug.sethook()
