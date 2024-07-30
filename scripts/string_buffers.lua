#!/usr/bin/env lua

local f = assert(io.open(arg[1], "r"))

local t = {}
for line in f:lines() do
    t[#t + 1] = line
end
t[#t + 1] = ""
local s = table.concat(t, "\n")

print(s)

f:close()
