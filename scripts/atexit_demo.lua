local t = {__gc = function ()
    -- 咱们的 'atexit' 代码在这里
    print('结束 Lua 程序')
end}

setmetatable(t, t)
_G["*AA*"] = t
