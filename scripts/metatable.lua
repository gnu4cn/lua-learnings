#!/usr/bin/env lua

t = {}
print(getmetatable(t))      --> nil

t1 = {}
setmetatable(t, t1)
assert(getmetatable(t) == t1)

print(getmetatable("hi"))               --> table: 000002634fa4aea0
print(getmetatable("xuxu"))             --> table: 000002634fa4aea0
print(getmetatable(10))                 --> nil
print(getmetatable(print))              --> nil
