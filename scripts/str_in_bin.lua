#!/usr/bin/env lua

local f = assert(io.open(arg[1], "rb"))
local data = f:read("a")

local validchars = "[%g%s]"
local pat = "(" .. string.rep(validchars, 6) .. "+)\0"

for w in string.gmatch(data, pat) do
    print(w)
end
