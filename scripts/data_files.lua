#!/usr/bin/env lua

local count = 0
function Entry () count = count + 1 end

dofile("data")

print("number of entries: " .. count)


local authors = {}      -- 收集作者的一个集合
function Entry (b)
    authors[b.author or "unknown"] = true
end

dofile("data")
for name in pairs(authors) do print(name) end


