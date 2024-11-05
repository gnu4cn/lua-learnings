#!/usr/bin/env lua
co = coroutine.create(function () print("hi") end);
print(type(co))             --> thread
print(coroutine.status(co))     --> suspended
coroutine.resume(co)    --> hi
print(coroutine.status(co))     --> dead
