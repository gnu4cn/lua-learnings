#!/usr/bin/env lua

local N = 3
local M = 3
local K = 2

local mt = {}           -- 创建矩阵
for i = 1, N do
    local row = {}      -- 创建一个新行
    mt[i] = row
    for j = 1, M do
        row[j] = 0
    end
end

local mt = {}           -- 创建矩阵
for i = 1, N do
    local aux = (i - 1) * M
    for j = 1, M do
        mt[aux + j] = 0
    end
end

for i = 1, M do
    for j = 1, N do
        c[i][j] = 0
        for k = 1, K
            c[i][j] = c[i][j] + a[i][k] * b[k][j]
        end
    end
end

-- 假定 'c' 的全部元素均为零
for i = 1, M do
    for k = 1, K
        for j = 1, N do
            c[i][j] = c[i][j] + a[i][k] * b[k][j]
        end
    end
end
