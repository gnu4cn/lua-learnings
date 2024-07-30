#!/usr/bin/env lua

local inp = assert(io.open(arg[1], "rb"))
local out = assert(io.open(arg[2], "wb"))

print(string.format("The input file: '%s', it'll be converted to '%s'.", arg[1], arg[2]))

local data = inp:read("a")
data = string.gsub(data, "\r\n", "\n")
out:write(data)

assert(out:close())
