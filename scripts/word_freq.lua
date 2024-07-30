#!/usr/bin/env lua

local f = assert(io.open("article", "r"))


local counter = {}
for l in f:lines() do
    for word in string.gmatch(l, "%w+") do
        if string.len(word) > 4 then
            counter[word] = (counter[word] or 0) + 1
        end
    end
end

f:close()

local words = {}    -- 在文本中找到的全部单词列表

for w in pairs(counter) do
    words[#words + 1] = w
end

table.sort(words, function(w1, w2)
    return counter[w1] > counter[w2]
    or (counter[w1] == counter[w2] and w1 < w2)
end)

-- 要打印的单词数目
local n = math.min(tonumber(arg[1]) or math.huge, #words)

for i = 1, n do
    io.write(words[i], "\t", counter[words[i]], "\n")
end
