#!/usr/bin/env lua

pair = "name = Anna"
k, v = string.match(pair, "(%a+)%s-=%s-(%a+)")
print(k, v)

date = "Today is 09/11/2023"

d, m, y = string.match(date, "(%d+)/(%d+)/(%d+)")
print(d, m, y)

s = [[then he said: "it's all right"!]]
q, quotedPart = string.match(s, "([\"'])(.-)%1")
print(q, quotedPart)

p = "%[(=*)%[(.-)%]%1%]"
s = "a = [=[[[ something ]] ]==] ]=]; print(a)"
print(string.match(s, p))


print((string.gsub("hello lua!", "%a", "%0-%0")))


print((string.gsub("hello Lua", "(.)(.)", "%2%1")))


s = [[the \quote{task} is to \em{change} that.]]
s = string.gsub(s, "\\(%a+){(.-)}", "<%1>%2<%1>")
print(s)
