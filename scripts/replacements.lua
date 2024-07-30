#!/usr/bin/env lua

function expand (s)
    return (string.gsub(s, "$(%w+)", function (n)
        return tostring(_G[n])
    end))
end

name = "Lua"; status = "great"
print(expand("$name is $status, isn't it?"))


print(expand("print = $print; a = $a"))

function toxml (s)
    s = string.gsub(s, "\\(%a+)(%b{})", function (tag, body)
        body = string.sub(body, 2, -2)  --> 移除花括号
        body = toxml(body)              --> 处理嵌套的命令
        return string.format("<%s>%s</%s>", tag, body, tag)
    end)
    return s
end

print(toxml("\\title{The \\bold{big} example}"))
