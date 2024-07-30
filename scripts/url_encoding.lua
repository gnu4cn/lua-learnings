#!/usr/bin/env lua

function unescape (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

print(unescape("a%2Bb+%3D+c"))

cgi = {}
function decode (s)
    for n, v in string.gmatch(s, "([^&=]+)=([^&=]+)") do
        n = unescape(n)
        v = unescape(v)
        cgi[n] = v
    end
end

function escape (s)
    s = string.gsub(s, "[&=+%%%c]", function (c)
        return string.format("%%%02X", string.byte(c))
    end)
    s = string.gsub(s, " ", "+")
    return s
end


function encode (t)
    local b = {}
    for k, v in pairs(t) do
        b[#b + 1] = (escape(k) .. "=" .. escape(v))
    end

    -- 连接 'b' 中所有的条目，以 ”&“ 分开
    return table.concat(b, "&")
end

t = {name = "al", query = "a+b = c", q = "yes or no"}
print(encode(t))
