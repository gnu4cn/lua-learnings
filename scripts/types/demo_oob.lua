local array = require "arraylib"

a = array.new(1000)
print(a:size()) --> 1000

a:set(10, true)
print(a:get(10)) --> true

a.set(a, 11, false)
print(a:get(11)) --> false
