#!/usr/bin/env lua

test = [[char s[] = "a /* here"; /* a tricky string */]]
print((string.gsub(test, "/%*.-%*/", "<COMMENT>")))
    --> char s[] = "a <COMMENT>

i, j = string.find(";$%  **#$hello13", "%a*")
print(i, j)

pattern = string.rep("[^\n]", 70) .. "+"


function nocase (s)
    s = string.gsub(s, "%a", function (c)
        return "[" .. string.lower(c) .. string.upper(c) .. "]"
    end)
    return s
end

print(nocase("Hi there!"))


function code (s)
    return (string.gsub(s, "\\(.)", function (x)
        return string.format("\\%03d", string.byte(x))
    end))
end

function decode (s)
    return (string.gsub(s, "\\(%d%d%d)", function (d)
        return "\\" .. string.char(tonumber(d))
    end))
end

s = [[follows a typical string: "This is \"greate\"!"]]

print(decode(string.gsub(code(s), '".-"', string.upper)))
