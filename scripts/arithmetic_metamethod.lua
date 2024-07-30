#!/usr/bin/env lua

local Set = require "mod_sets"

s1 = Set.new{10, 20, 30, 50}
s2 = Set.new{30, 1}
print(getmetatable(s1))         --> V8K4Rwux72nEYFfSDTWmCp
print(getmetatable(s2))         --> V8K4Rwux72nEYFfSDTWmCp

s3 = s1 + s2
print("s1: ", s1, "s2: ", s2)
print("s1 + s2 = ", s3)       --> {1, 30, 10, 20, 50}
print("s1 x s2 = ", s2 * s1)  --> {30}

s1 = Set.new{2, 4}
s2 = Set.new{2, 10, 4}
print(s1 <= s2)         --> true
print(s1 < s2)          --> true
print(s1 >= s2)         --> false
print(s1 > s2)          --> false
print(s1 == s2 * s1)    --> true


s1 = Set.new{10, 4, 5}
print(s1)       --> {10, 5, 4}


s1 = Set.new{}
print(getmetatable(s1))     --> V8K4Rwux72nEYFfSDTWmCp
setmetatable(s1, {})
    -->  stdin:30: cannot change a protected metatable
