#!/usr/bin/env lua

local m = require "math"
print(m.sin(3.14))

function search (modname, path)
    modname = string.gsub(modname, "%.", "/")
    local msg = {}
    for c in string.gmatch(path, "[^;]+") do
        local fname = string.gsub(c, "?", modname)
        local f = io.open(fname)
        if f then
            f:close()
            return fname
        else
            msg[#msg + 1] = string.format("\n\tno file '%s'", fname)
        end
    end
    return nil, table.concat(msg)       -- 未找到
end
