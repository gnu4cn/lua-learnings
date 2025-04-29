local array = require "arraylib"

a = array.new(1000)

a[10] = true -- 'setarray'
print(a[10]) -- 'getarray' --> true
print(#a) -- 'getsize' --> 1000

