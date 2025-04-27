local mylib = require "mylib"

x = mylib.new_tuple(10, "hi", {}, 3)
print(x(1))
print(x(2))
print(x())

print(x(10))
