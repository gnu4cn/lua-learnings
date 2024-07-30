#!/usr/bin/env lua

local date = 1439653520
local day2year = 365.242                -- 一年中的天数
local sec2hour = 60 * 60                -- 一小时的秒数
local sec2day = sec2hour * 24           -- 一天中的秒数
local sec2year = sec2day * day2year     -- 一年中的秒数

-- 年份
print(date // sec2year + 1970)        --> 2015.0

-- 小时（按 UTC）
print(date % sec2day // sec2hour)     --> 15

-- 分钟
print(date % sec2hour // 60)          --> 45

-- 秒
print(date % 60)                      --> 20

t = 906000490
-- ISO 8601 的日期
print(os.date("%Y-%m-%d", t))           --> 1998-09-17

-- 组合了日期和时间的 ISO 8601 格式
print(os.date("%Y-%m-%dT%H:%M:%S", t))  --> 1998-09-17T10:48:10

-- ISO 8601 的序数日期
print(os.date("%Y-%j", t))              --> 1998-260

t = os.date("*t")           -- 获取当前日期
print(os.date("%Y/%m/%d", os.time(t)))        --> 2023/11/12
t.day = t.day + 40
print(os.date("%Y/%m/%d", os.time(t)))        --> 2023/12/22

t = os.date("*t")
print(t.day, t.month)               --> 12      11
t.day = t.day - 40
print(t.day, t.month)               --> -28     11
t = os.date("*t", os.time(t))
print(t.day, t.month)               --> 3       10

t = os.date("*t")           -- 获取当前日期
print(os.date("%Y/%m/%d", os.time(t)))        --> 2023/11/12
t.month = t.month + 6       -- 此后 6 个月
print(os.date("%Y/%m/%d", os.time(t)))        --> 2024/05/12


local t5_3 = os.time({year=2015, month=1, day=12})
local t5_2 = os.time({year=2011, month=12, day=16})
local d = os.difftime(t5_3, t5_2)
print(d // (24 * 3600))

myepoch = os.time {year = 2000, month = 1, day = 1, hour = 0}
now = os.time {year = 2023, month = 11, day = 12}
t = os.difftime(now, myepoch)
print(t)       --> 753105600.0

T = {year = 2000, month = 1, day = 1, hour = 0}
T.sec = 753105600
print(os.date("%d/%m/%Y", os.time(T)))  --> 12/11/2023

local x = os.clock()
local s = 0
for i = 1, 100000 do s = s+ i end
print(string.format("经过时间：%.8f\n", os.clock() - x))
    --> 经过时间：0.00035900
