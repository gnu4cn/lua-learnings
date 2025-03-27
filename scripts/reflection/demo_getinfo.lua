local debug = require "debug"

local a = 1

print(debug.getinfo(a).what)
print(debug.getinfo(a).nups)
print(debug.getinfo(a).nparams)
print(debug.getinfo(a).isvararg)
print(debug.getinfo(a).activelines)
print(debug.getinfo(a).linedefined)
print(debug.getinfo(a).lastlinedefined)
