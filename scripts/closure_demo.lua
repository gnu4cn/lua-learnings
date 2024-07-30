#!/usr/bin/env lua

network = {
    {name = "grauna",   IP = "210.26.30.34"},
    {name = "arraial",  IP = "210.26.30.23"},
    {name = "lua",      IP = "210.26.23.12"},
    {name = "derain",   IP = "210.26.23.20"},
}

table.sort(network, function (a, b) return (a.name > b.name) end)

for _, r in pairs(network) do
    for name, ip in pairs(r) do
        print(name, ip)
    end
end
