local array = require "arraylib"

a = array.new(1000)

for i = 1, 1000 do
    array.set(a, i, i % 2 == 0)     -- a[i] = (i % 2 == 0)
end

print(array.get(a, 10))
print(array.get(a, 11))
print(array.size(a))
