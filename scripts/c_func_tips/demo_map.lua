local mylib = require "mylib"

function foo (x) return 2*x end

t = {1, 2, 3, 4}
for k, v in pairs(t) do print(v) end

print("---")

mylib.map(t, foo)
for k, v in pairs(t) do print(v) end
