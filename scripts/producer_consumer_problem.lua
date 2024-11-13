function producer ()
    while true do
        local x = io.read()     -- 产生新值
        send(x)                 -- 将其发送给消费者
    end
end

function consumer ()
    while true do
        local x = receive()     -- 从生产者接收值
        io.write(x, "\n")       -- 消费该值
    end
end

producer = coroutine.create(producer)

function receive ()
    local status, value = coroutine.resume(producer)
    return value
end

function send (x)
    coroutine.yield(x)
end
