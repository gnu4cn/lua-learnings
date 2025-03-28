debug = require("debug")

debug.sethook(print, "l")
local a = 10
print(a)


debug.sethook()
