#!/usr/bin/env lua

print(string.match("hello", "()ll()"))

function expandTabs (s, tab)
    tab = tab or 8      -- 制表符的 ”大小“ （默认为 8）
    local corr = 0      -- 校准

    s = string.gsub(s, "()\t", function (p)
        local sp = tab - (p - 1 + corr)%tab
        corr = corr - 1 + sp
        return string.rep(" ", sp)
    end)
    return s
end

s = expandTabs("name\tage\tnationality\tgender", 8)


function unexpandTabs (s, tab)
    tab = tab or 8
    s = expandTabs(s, tab)

    local pat = string.rep(".", tab)
    s = string.gsub(s, pat, "%0\1")
    print(s)
    s = string.gsub(s, " +\1", "\\t")
    print(s)
    s = string.gsub(s, "\1", "")
    return s
end

print(unexpandTabs(s))
