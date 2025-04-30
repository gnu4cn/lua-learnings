local lxp = require "lxp"

p = lxp.new(callbacks) -- create new parser

for l in io.lines() do -- iterate over input lines
    assert(p:parse(l)) -- parse the line
    assert(p:parse("\n")) -- add newline
end

assert(p:parse()) -- finish document
p:close() -- close parser
