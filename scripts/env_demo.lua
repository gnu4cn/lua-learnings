f = load("b = 10; return a")

env = {a = 20}
debug.setupvalue(f, 1, env)
print(f())
print(env.b)
