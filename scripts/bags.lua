#!/usr/bin/env lua

function insert (bag, element)
    bag[element] = (bag[element] or 0) + 1
end

function remove (bag, element)
    local count = bag[element]
    bag[element] = (count and count > 1) and count - 1 or nil
end
