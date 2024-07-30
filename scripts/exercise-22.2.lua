local foo
do
    local _ENV = _ENV
    function foo () print(X) end
end
foo()
X = 13
-- for i in pairs(_ENV) do print(i) end
_ENV = nil
foo()
X = 0
