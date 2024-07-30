#!/usr/bin/env lua

s = "Most pattern-matching libraries use the backslash as an escape. However, this choice has some annoying consequences. For the Lua parser, patterns are regular strings."

words = {}
for w in string.gmatch(s, "%a+") do
    words[#words + 1] = w
end

print(s)
for _, w in pairs(words) do print(w) end
