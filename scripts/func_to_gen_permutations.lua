function permgen (a, n)
    n = n or #a         -- `n` 的默认值为 `a` 的大小
    if n <= 1 then
        printResult(a)
    else
        for i = 1, n do
            
            -- 将第 i 个元素置为最后一个
            a[n], a[i] = a[i], a[n]

            -- 生成全部其他元素的排列
            permgen(a, n - 1)


            -- 恢复第 i 个元素
            a[n], a[i] = a[i], a[n]
        end
    end
end

function printResult (a)
    for i = 1, #a do io.write(a[i], " ") end
    io.write("\n")
end

permgen ({1, 2, 3, 4})
