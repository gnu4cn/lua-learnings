#!/usr/bin/env lua
require "markov_chain"
io.input("article")

local MAXGEN = 200
local NOWORD = "\n"

-- 构建出表
local w1, w2 = NOWORD, NOWORD
for nextword in allwords() do
    insert(prefix(w1, w2), nextword)
    w1 = w2; w2 = nextword
end
insert(prefix(w1, w2), NOWORD)

-- 生成文本
w1 = NOWORD; w2 = NOWORD        -- 重新初始化
for i = 1, MAXGEN do
    local list = statetab[prefix(w1, w2)]
    -- 从清单选择一个随机项目
    local r = math.random(#list)
    local nextword = list[r]
    if nextword == NOWORD then return end
    io.write(nextword, " ")
    w1 = w2; w2 = nextword
end
