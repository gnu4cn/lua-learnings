#!/usr/bin/env lua

a = {p = print}         -- 'a.p' 指向函数 'print'
a.p("Hello World")      -- Hello World

print = math.sin        -- 'print' 现在指向正弦函数
a.p(print(1))           -- 0.8414709848079

math.sin = a.p          -- 'sin' 现在指向打印函数
math.sin(10, 20)        -- 10       20
