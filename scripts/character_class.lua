#!/usr/bin/env lua

s = "Deadline is 30/11/2023, firm"
date = "%d%d/%d%d/%d%d%d%d"
print(string.match(s, date))    --> 30/11/2023


text = [[One teenage girl compared the mass movement to the “Nakba,” or catastrophe, the Arabic term for the expulsion of Palestinians from their towns during the founding of Israel.

It was the fifth day in a row that the IDF opened an evacuation window, and numbers of people fleeing south have increased each day.

The UN said 2,000 had fled south on Sunday, rising to 15,000 on Tuesday. The Israeli government said 50,000 Gazans travelled via the evacuation corridor Wednesday. That number could not be independently verified, but a CNN journalist at the scene said the numbers leaving were larger than on Tuesday.

Israel has been ramping up its offensive inside Gaza, following the October 7 attacks that left 1,400 people in Israel dead.
]]


_, nvow = string.gsub(text, "[aeiouAEIOU]", "")
print(nvow)


test = "int x; /* x */  int y; /* y */"
print((string.gsub(test, "/%*.*%*/", "")))

test = "int x; /* x */  int y; /* y */"
print((string.gsub(test, "/%*.-%*/", "")))

s = "a (enclosed (in) parentheses) line"
print((string.gsub(s, "%b()", "")))


s = "the anthem is the theme"
print((string.gsub(s, "%f[%w]the%f[%W]", "one")))
