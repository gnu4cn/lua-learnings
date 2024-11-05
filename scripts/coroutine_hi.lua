#!/usr/bin/env lua
co = coroutine.create(function () print("hi") end)
print(type(co))
