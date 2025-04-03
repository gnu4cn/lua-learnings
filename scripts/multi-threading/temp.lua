local socket = require "socket"
local ssl = require "ssl"

local host = "www.lua.org"
local file = "/manual/5.3/manual.html"

-- TLS/SSL client parameters (omitted)
local params = {
    mode = "client",
    protocol = "any",
    verify = "none",
    options = "all",
}

local conn = socket.tcp()
conn:settimeout(0)
conn:connect(host, 443)

-- TLS/SSL initialization
conn = ssl.wrap(conn, params)
conn:dohandshake()

-- 请求必须构造成下面这样，否则返回 400 Bad Request
local req = string.format(
    "GET %s HTTP/1.1\r\nHost: %s\r\n\r\n", file, host)
conn:send(req)
conn:settimeout(0)

local body = ""
while true do
    -- 这里返回三个值，响应字符串，状态和时间
    -- 其中状态有三个取值：`nil`、`wantread` 和 `closed`。有响应时为 `nil`，无响应时为 `wantread`，直到最后 `closed`
    -- 开始有响应前，和响应结束后，状态都是 `wantread`，响应字符串为 `nil`
    -- 读取过程中响应字符串为非 `nil` 的字符串
    local s, status, t = conn:receive(2^10)

    if status == nil then body = body .. s end
    if status == "closed" then break end
end

conn:close()

print(body)
