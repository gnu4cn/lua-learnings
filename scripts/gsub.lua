#!/usr/bin/env lua

s = string.gsub("Lua is cute", "cute", "great")
print(s)        --> Lua is great

s = string.gsub("all lii", "l", "x")
print(s)        --> axx xii

s = string.gsub("Lua is great", "Sol", "Sun")
print(s)        --> Lua is great

s = string.gsub("all lii", "l", "x", 1)
print(s)        --> axl lii

s = string.gsub("all lii", "l", "x", 2)
print(s)        --> axx lii

