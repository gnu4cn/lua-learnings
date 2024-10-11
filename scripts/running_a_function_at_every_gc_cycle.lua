do
    local mt = {__gc = function (o)
        -- 咱们要完成的事情
        print("新的周期")
        -- 为下一周期创建新的对象
        setmetatable({}, getmetatable(o))
    end}
    -- 创建首个对象
    setmetatable({}, mt)
end

collectgarbage()    --> 新的周期
collectgarbage()    --> 新的周期
collectgarbage()    --> 新的周期
