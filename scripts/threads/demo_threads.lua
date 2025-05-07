local lproc = require "lproc"

chunk1 = [[
    local lproc = require "lproc"
    lproc.send("ch", "test", "this")
]]

L1 = lproc.start('')
L2 = lproc.start('')

print(L1)
lproc.exit()
