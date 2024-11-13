#!/usr/bin/env lua

co = coroutine.create(function ()
    for i =1, 10 do
        print("co", i)
        coroutine.yield()
    end
end)

coroutine.resume(co)    --> co      1
print(coroutine.status(co))     --> suspended
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
coroutine.resume(co)
print(coroutine.resume(co))
