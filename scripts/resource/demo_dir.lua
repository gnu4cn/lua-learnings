local dir = require "dir"


for fname in dir.open(".") do
    print(fname)
end

