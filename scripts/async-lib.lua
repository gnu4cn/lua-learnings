local cmdQueue = {}         -- 待处理操作队列

local lib = {}

function lib.readline (stream, callback)
    local nextCmd = function ()
        callback(stream:read())
    end

    table.insert(cmdQueue, nextCmd)
end

function lib.writeline ()
    local nextCmd = function ()
        callback(stream:write(line))
    end

    table.insert(cmdQueue, nextCmd)
end

function lib.stop ()
    table.insert(cmdQueue, "stop")
end

function lib.runloop ()
    while true do
        local nextCmd = table.remove(cmdQueue, 1)

        if nextCmd == "stop" then
            break
        else
            nextCmd()       -- 执行下一操作
        end
    end
end

return lib
