#!/usr/bin/env lua

local function name2node (graph, name)
    local node = graph[name]

    if not node then
        -- 节点不存在；要创建一个新的节点
        node = {name = name, adj = {}}
        graph[name] = node
    end

    return node
end


function readgraph (filename)
    local graph = {}
    local f = assert(io.open(filename, "r"))

    for line in f:lines() do
        -- 将行拆分为两个名字
        local namefrom, nameto = string.match(line, "(%S+)%s+(%S+)")
        -- 找到相应节点
        local from = name2node(graph, namefrom)
        local to = name2node(graph, nameto)
        -- 将 'to' 添加到 `from` 的邻接集合
        from.adj[to] = true
    end
    f:close()

    return graph
end

function findpath (curr, to, path, visited)
    path = path or {}
    visited = visited or {}

    if visited[curr] then       -- 节点已被访问过？
        return nil              -- 此处无路径
    end

    visited[curr] = true       -- 将节点标记为已访问过
    path[#path + 1] = curr      -- 将其添加到路径
    if curr == to then          -- 最终节点？
        return path
    end
    -- 尝试全部邻接节点
    for node in pairs(curr.adj) do
        local p = findpath(node, to, path, visited)
        if p then return p end
    end
    table.remove(path)          -- 从路径种移除节点
end


function printpath (path)
    for i = 1, #path do
        print(path[i].name)
    end
end

g = readgraph("demo.graph")
a = name2node(g, "a")
b = name2node(g, "b")
p = findpath(a, b)
if p then printpath(p) end
