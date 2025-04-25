local mylib = require "mylib"

t = mylib.split("hi:ho:there", ":")

for k, v in pairs(t) do print(v) end
