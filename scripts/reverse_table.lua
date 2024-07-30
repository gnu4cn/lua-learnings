#!/usr/bin/env lua

days = {"Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"}

revDays = {["Sunday"] = 1, ["Monday"] = 2,
           ["Tuesday"] = 3, ["Wednesday"] = 4,
           ["Thursday"] = 5, ["Friday"] = 6,
           ["Saturday"] = 7}

x = "Tuesday"
print(revDays[x])


revDays = {}
for k, v in pairs(days) do
    revDays[v] = k
end

x = "Friday"
print(revDays[x])

