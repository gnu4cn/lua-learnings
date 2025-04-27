local mylib = require "mylib"

c1 = mylib.newCounter()
print(c1(), c1(), c1())

c2 = mylib.newCounter()
print(c2(), c2(), c1())
