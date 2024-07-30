#!/usr/bin/env lua
goto room1          -- 初始房间

::room1:: do
    local move = io.read()
    if move == "south" then goto room3
    elseif move == "east" then goto room2
    else
        print("Invalid move")
        goto room1
    end
end

::room2:: do
    local move = io.read()
    if move == "south" then goto room4
    elseif move == "west" then goto room1
    else
        print("Invalid move")
        goto room2
    end
end

::room3:: do
    local move = io.read()
    if move == "north" then goto room1
    elseif move == "east" then goto room4
    else
        print("Invalid move")
        goto room3
    end
end

::room4:: do
    print("Congratulations, you won!")
end

