# 面向对象编程

**Object-Oriented Programming**


Lua 中的表，在不止一种意义上是个对象。与对象一样，表也有状态。与对象一样，表也有一个与其值无关的身份（`self`）。具体来说，具有相同值的两个对象（表）是不同的对象，而某个对象在不同时间，亦可以具有不同值。与对象一样，表的生命周期与创建者或在何处被创建无关。


对象有自己的操作。表也可以有操作，如下面的代码片段：


```lua
Account = {balance = 0}
function Account.withdraw (v)
    Account.balance = Account.balance - v
end
```

该定义创建了一个新函数，并将其存储在对象 `Account` 的 `withdraw` 字段中。然后，我们可以像这样调用他：


```lua
Account.withdraw(100.00)
```


这种函数几乎就是我们所说的方法。然而，在函数中使用全局的名字 `Account` 是一种可怕的编程做法。首先，该函数只对这个特定对象有效。其次，即使是这个特定的对象，只要该对象仍存储在这个特定的全局变量中，函数就会起作用。如果我们更改了对象的名称， `withdraw` 就不再起作用了：


```console
> a, Account = Account, nil
> a.withdraw(100.00)
lib/account.lua:3: attempt to index a nil value (global 'Account')
stack traceback:                                                                                                                                  lib/account.lua:3: in function <lib/account.lua:2>                                                                                        (...tail calls...)                                                                                                                        [C]: in ?
```


此类行为违反了对象具有独立生命周期的原则，the principle that objects have independent life cycles。


一种更具原则性的方法，是对操作的 *接收者，receiver* 进行操作。为此，我们的方法需要一个包含接收者值的额外参数。这个参数的名称，通常是 `self` 或 `this`：


```lua
function Account.withdraw (self, v)
    self.balance = self.balance - v
end
```


现在，当我们调用该方法时，就必须指定他要操作的对象：


```console
$ lua -i lib/account.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> a1, Account = Account, nil
> a1.balance = 1000.00
> a1.withdraw(a1, 100.00)
> print(a1.balance)                                                                                                                       900.0
```

通过 `self` 参数的使用，我们便可以对多个对象，使用这同一个方法：


```console
$ lua -i lib/account.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> a2 = {balance=0, withdraw = Account.withdraw}
> a2.withdraw(a2, 260.00)
> print(a2.balance)                                                                                                                       -260.0
```

`self` 参数的使用，是任何面向对象语言的核心要点。大多数面向对象编程语言，对程序员隐藏了这一机制，因此程序员不必声明这一参数（不过仍可在方法中使用 `self` 或 `this` 的名字）。Lua 也可以通过 *冒号操作符, the colon operator*，来隐藏这个参数。使用他，咱们就可以将之前的方法调用，重写为 `a2:withdraw(260.00)`，并将之前的定义重写为下面这样：


```lua
function Account:withdraw (v)
    self.balance = self.balance - v
end
```


冒号的作用，是在方法调用中增加一个额外的参数，并在方法定义中增加一个额外的隐藏参数。冒号仅是一种语法工具，a syntactic facility, 尽管很方便；这里并没有什么新东西。我们可以用点语法定义一个函数，然后用冒号语法调用他，反之亦然，只要我们能正确处理额外的参数：


```lua
Account = {balance = 0,
    withdraw = function (self, v)
        self.balance = self.balance - v
    end
}

function Account:deposit (v)
    self.balance = self.balance + v
end
```


```console
$ lua -i lib/account.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> Account.deposit(Account, 2000.00)
> Account.balance
2000.0
> Account:withdraw(150.00)
> Account.balance                                                                                                  1850.0
```



## 类

**Classes**


到目前为止，我们的对象已经有了身份、状态和对状态的操作。他们仍然缺乏类系统、继承和隐私，lack a class system, inheritance, and privacy。咱们来解决第一个问题：如何创建具有相似行为的多个对象？具体来说，我们如何创建多个账户？


大多数面向对象编程语言，都提供类的概念，其充当了创建对象的模具。在这类语言中，每个对象都是个特定类的实例。Lua 没有类的概念；元表的概念有些类似，但将其用作类，并不会让我们走得太远。相反，我们可以效仿基于原型的语言（如 [Self](https://selflanguage.org/)，Javascript 同样遵循了这条路径），在 Lua 中模拟出类。在这些语言中，对象同样没有类。相反，每个对象都可能有是个常规对象的原型，a prototype, which is a regular object，首个对象会在原型中，查找他不知道的任何操作。要在这类语言中表示类，我们只需创建一个对象，专门用作其他对象（其实例）的原型。类和原型，都是放置多个对象共用行为的地方。


在 Lua 中，我们可以使用在 [`__index` 元方法](https://hpcl.xfoss.com/lua_tut/metatables_and_metamethods.html#__index-%E6%96%B9%E6%B3%95) 小节中，看到的继承概念来实现原型。更具体地说，如果我们有两个对象 `A` 和 `B`，要使 `B` 成为 `A` 的原型，我们只需这样做：


```lua
    setmetable(A, {__index = B})
```


之后，`A` 会在 `B` 中，查找他没有的任何操作。把 `B` 看作对象 `A` 的类，不过是术语上的变化而已。


咱们回到银行账户的例子。要创建行为与 `Account` 类似的其他账户，我们可以使用 `__index` 元方法，让这些新对象从 `Account` 继承其操作。


```lua
local mt = {__index = Account}

function Account.new (o)
    o = o or {}     -- 若用户没有提供表，就要创建出表
    setmetatable(o, mt)
    return o
end
```

在这段代码之后，当我们创建一个新账户并调用某个方法时，会发生什么呢？


```console
$ lua -i lib/account.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> a = Account.new{balance = 0}
> a:deposit(100.00)
> a.balance
100.0
```

当我们创建新帐户 `a` 时，他将使用 `mt` 作为其元表。当我们调用 `a:deposit(100.00)` 时，我们实际上是在调用 `a.deposit(a, 100.00)`；冒号只是语法糖。然而，Lua 在表 `a` 中找不到 `deposit` 条目；因此，Lua 会查看元表的 `__index` 条目。现在的情况或多或少是这样的:

```lua
getmetatable(a).__index.deposit(a, 100.00)
```


`a` 的元表是 `mt`，而 `mt.__index` 是 `Account`。因此，前一个表达式就会求值到这个表达式：


```lua
Account.deposit(a, 100.00)
```

也就是说，Lua 调用了原先的 `deposit` 函数，但将 `a` 作为 `self` 参数传递。因此，这个新账户 `a` 就从 `Account` 继承了 `deposit` 函数。通过同样的机制，他也继承了 `Account` 的所有字段。

我们可以对这种方案做两处小的改进。首先，我们不需要为其中的元表角色，创建一个新表；相反，我们可以使用 `Account` 表本身，来实现这一目的。第二处改进是，我们也可以为 `new` 方法使用冒号语法。有了这两处改动，方法 `new` 就变成了下面这样：


```lua
function Account:new (o)
    o = o or {}
    self.__index = self
    setmetatable(o, self)
    return o
end
```

现在，当我们调用 `Account:new()` 时，那个隐藏参数 `self` 的值，即为 `Account`，我们使 `Account.__index` 同样等于 `Account`，进而将 `Account` 设置为其中新对象的元表。第二处改动（其中的冒号语法），似乎并没有给我们带来什么好处；在下一节中介绍类的继承时，使用 `self` 的好处就会显现出来。


继承不仅适用于方法，也适用于在新账号中，缺失的其他字段。因此，某个类不仅可以提供方法，还可以为其实例的字段，提供常量及默认值。请记住，在 `Account` 的首个定义中，我们提供了一个值为 `0` 的字段 `balance`。因此，如果我们创建出一个没有初始余额的新账户，他将继承这个默认值：


```console
$ lua -i lib/account.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> b = Account:new()
> print(b.balance)                                                                                                                 0
0
```

当我们调用 `b` 上的 `deposit` 方法时，他会运行与以下代码等效的代码，因为 `self` 就是 `b`：

```lua
b.balance = b.balance + v
```

其中的表达式 `b.balance` 的计算结果为零，并且该方法会将初始存款，分配给 `b.balance`。后续访问 `b.balance` 将不会调用索引的元方法，因为现在 `b` 有了自己的 `balance` 字段。


## 继承

**Inheritance**


因为类属于对象，所以他们也可以从其他类中获取方法。这种行为使得继承（在通常的面向对象意义上）就很容易在 Lua 中实现。

假设我们有个如下 [图 21.1 中 “`Account` 类”](#f-21.1) 的基类，a base class。


<a name="f-21.1">**图 21.1 `Account` 类**</a>


```lua
Account = {balance = 0}

function Account:new (o)
    o = o or {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function Account:deposit (v)
    self.balance = self.balance + v
end

function Account:withdraw (v)
    if v > self.balance then error"资金不足" end
    self.balance = self.balance - v
end
```


现在我们打算从该类，派生出一个允许客户提取超过余额金额的子类 `SpecialAccount`。我们从一个直接从其基类，继承了所有操作的空类开始：


```lua
SpecialAccount = Account:new()
```


到目前为止，`SpecialAccount` 还只是 `Account` 的一个实例。现在，神奇的事情发生了：


```console
s = SpecialAccount:new{limit=1000.00}
```


和其他方法一样，`SpecialAccount` 从 `Account` 继承了 `new`。不过，这次 `new` 执行时，他的 `self` 参数将指向 `SpecialAccount`。因此，`s` 的元表将是 `SpecialAccount`，其字段 `__index` 的值也是 `SpecialAccount`。因此，`s` 继承自 `SpecialAccount`，而 `SpecialAccount` 又继承自 `Account`。稍后，当我们对 `s:deposit(100.00)` 求值时，Lua 无法在 `s` 中找到 `deposit` 字段，因此他会查找 `SpecialAccount`；他也无法在 `SpecialAccount` 中找到 `deposit` 字段，因此他会查找 `Account`；在 `Account` 中他就找到了 `deposit` 的原始实现。

`SpecialAccount` 的特别之处在于，我们可以重新定义从其超类继承到的任何方法。我们只需编写出新方法即可：


```lua
function SpecialAccount:withdraw (v)
    if v - self.balance > self:getLimit() then
        error"无效金额"
    end
    self.balance = self.balance -v
end

function SpecialAccount:getLimit ()
    return self.limit or 0
end
```


现在，当我们调用 `s:withdraw(200.00)` 时，Lua 就不会转到 `Account` 了，因为他首先会在 `SpecialAccount` 中找到新的 `withdraw` 方法。由于 `s.limit` 是 `1000.00`（请记住，我们在创建 `s` 时设置了这个字段），程序会执行提款操作，使 `s` 的余额为负数。


Lua 中对象的一个有趣之处在于，我们无需为指明某个新的行为，而创建出一个心累。在只有一个对象需要特定行为时，我们可以直接在对象中，实现该行为。例如，如果账户 `s` 代表某名特殊客户，其限额总是余额的 10%，我们就可以只修改这个单一账户：


```console
    function s:getLimit ()
        return self.balance * 0.1
    end
```

在此声明之后，调用 `s:withdraw(200.00)` 就会运行 `SpecialAccount` 的 `withdraw` 方法，但 `withdraw` 调用 `self:getLimit` 时，调用的便是这个最新的定义。



## 多重继承


**Multiple Inheritance**



由于在 Lua 中对象并非原语（not primitive），因此在 Lua 中进行面向对象编程就有多种方法。我们已看到的使用索引元方法，可能是简单、性能和灵活性的最佳组合。不过，还有其他一些实现方法，他们可能更适合某些特殊情况。下面我们将介绍一种，允许在 Lua 中进行多重继承的替代实现方法。


这种实现的关键，是 `__index` 元字段的一个函数的运用。请记住，当某个表在其 `__index` 字段中，有着一个函数时，那么只要 Lua 在该原始表中找不到某个键时，他就会调用这个函数。随后，`__index` 就会在他想要的父类中，查找这个缺失的键。


多重继承意味着类不再有唯一的超类。因此，我们不应再使用（超）类方法来创建子类。相反，我们将为此定义一个独立函数 `createClass`，其参数是新类的所有超类；参见下 [图 21.2 “多重继承的实现”](#f-21.2)。这个函数创建了一个表示新类的表，并用一个 `__index` 元方法，来设置其元方法，从而实现多重继承。尽管存在多重继承，每个对象实例仍属于一个类，并在该类中查找所有方法。因此，类与超类之间的关系，不同于实例与类之间的关系。尤其是，某个类不能同时成为其实例和子类的元表。在 [图 21.2 “多重继承的实现”](#f-21.2) 中，我们保留了类作为其实例的元表，并创建另一个表作为该类的元表。


<a name="f-21.2">**图 21.2 多重继承的实现**</a>

```lua
-- 在表 `plist` 的列表种查找 `k`
local function search (k, plist)
    for i = 1, #plist do
        local v = plist[i][k]   -- 尝试第 `i` 个超类
        if v then return v end
    end
end

function createClass (...)
    local c = {}            -- 新类
    local parents = {...}   -- 父类的列表

    -- 类在其父类列表中检索缺失的方法
    setmetatable (c, {__index = function (t, k)
        return search (k, parents)
    end})

    -- 准备 `c` 作为其实例的元表
    c.__index = c

    -- 定义这个新类的新构造器
    function c:new (o)
        o = o or {}
        setmetatable (o, c)
        return o
    end

    return c
end
```

我们来用一个小的示例，来说明 `createClass` 的使用。假设咱们之前的类 `Account` 和另一个只有两个方法：`setname` 和 `getname` 的类 `Named`。


```lua
Named = {}
function Named:getname ()
    return self.name
end
function Named:setname (n)
    self.name = n
end
```


要创建一个同时是 `Account` 和 `Named` 子类的新类 `NamedAccount`，我们只需调用 `createClass` 即可：

```lua
NamedAccount = createClass(Account, Named)
```

要创建和使用实例，我们照常进行：


> **注**：在 Lua 控制台，或 Lua 脚本中使用 `dofile("lib/account.lua")`、`dofile("lib/Named.lua")` 及 `dofile("lib/multi_inheritance.lua")`，将上述库代码加载到程序中。

```lua
> account = NamedAccount:new{name = "Paul"}
> account.name
Paul
> account:getname()
Paul
```




现在，我们来看看 Lua 是如何计算出 `account:getname()` 表达式的；更具体地说，我们来看看 `account["getname"]` 的求值过程。Lua 无法在 `account` 中找到字段 `"getname"`；因此，Lua 会查找 `account` 元表，在咱们的例子中即 `NamedAccount` 上的 `__index` 字段。但 `NamedAccount` 也无法提供 `getname` 字段，因此 Lua 会查找 `NamedAccount` 元表中的 `__index` 字段。因为这个字段包含着一个函数，所以 Lua 便调用了他。该函数首先在 `Account` 中查找 `getname`，但没有成功，然后在 `Named` 中查找，在 `Named` 中找到了一个非零值（a non-nil value），这就是本次检索的最终结果。


当然，由于这种搜索的潜在复杂性，多重继承的性能与单一继承并不相同。提高性能的一种简单办法是将所继承的方法，复制到子类中。使用这种技巧，类的索引元方法，将如下所示：


```lua
    setmetatable (c, {__index = function (t, k)
        local v = search (k, parents)
        t[k] = v    -- 保存用于下次访问
        return v
    end})
```


通过这个技巧，除了第一次外，对所继承方法的访问，与对本地方法的访问一样快。缺点是程序启动后，就很难更改方法定义了，因为这些更改不会在层次链中向下传播，these changes do not propagate down the hierarchy chain。


## 隐私问题

**Privacy**


许多人把隐私（也称为 *信息隐藏，information hiding*），看着是面向对象语言不可分割的一部分：每个对象的状态，应是其内部事务。在 C++ 和 Java 等一些面向对象语言中，我们可以控制某个字段（也称为 *实例变量，instance variable*）或方法，是否在对象外部可见。让面向对象语言变得流行起来的 Smalltalk，就把所有变量私有，而把所有方法公开。而有史以来的第一种面向对象语言 Simula，却没有提供任何保护。


我们之前已经展示过 Lua 中，对象的标准实现，其并未提供隐私机制。部分原因是我们使用了通用结构（a general structure，表）来表示对象。此外，Lua 避免了冗余和人为限制。如果咱们不打算访问对象内部的内容，那就 *不要访问*。一种常见的做法，是在所有私有名字的末尾加上下划线。当咱们看到一个被标记的名字在公共场合使用时，就会立刻感觉到这种气氛。


不过，Lua 的另一个目标是灵活性，为程序员提供元机制，meta-mechanisms，使其能够模拟许多不同机制。虽然 Lua 中对象的基本设计并未提供隐私机制，但我们可以用一种不同方式，实现具有访问控制的对象。虽然程序员并不经常使用这种实现方式，但了解这种方式还是很有意义的，因为他探究了 Lua 的一些有趣方面，而且是解决更多具体问题的好办法。


这种替代设计的基本思想，是通过两个表来表示每个对象：一个表表示对象的状态，另一个表示对象的操作或其接口。我们通过第二个表，即通过构成对象接口的操作，来访问对象本身。为了避免未经授权的访问，代表对象状态的表，不会保存在另一个表的字段中；相反，他只会保存在方法的闭包中。例如，要使用这种设计，来表示我们的银行账户，我们可以通过运行以下工厂函数，factory function，来创建新的对象：


```lua
function newAccount (initialBalance)
    local self = {balance = initialBalance}

    local withdraw = function (v)
                        self.balance = self.balance -v
                    end

    local deposit = function (v)
                        self.balance = self.balance + v
                    end

    local getBalance = function () return self.balance end


    return {
        withdraw = withdraw,
        deposit = deposit,
        getBalance = getBalance
    }

end
```

首先，该函数创建了一个表，来保存对象的内部状态，并将其存储在局部变量 `self` 中。然后，该函数创建了这个对象的方法。最后，该函数创建并返回了将方法名称，映射到实际的方法实现的外部对象，external object。这里的关键点是，这些方法不会将 `self` 作为额外参数，而是直接访问 `self`。因为没有额外参数，所以我们就不使用冒号语法，来操作这些对象。我们就像调用普通函数一样，调用他们的方法：


```console
$ lua -i lib/account.neo.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> acc1 = newAccount(100.00)
> acc1.withdraw(40.00)
> acc1.getBalance()
60.0
> acc1.balance                                                                                                                                  nil
```


这种设计为存储在 `self` 表中任何的内容，提供了完全的隐私。在对 `newAccount` 的调用返回后，就无法直接访问这个表了。我们只能通过 `newAccount` 内部创建的函数来访问他。尽管我们的示例只在那个私有表中，放入了一个实例变量，但我们可以在这个表中，存储对象的所有私有部分。我们还可以定义私有方法：他们与公开方法类似，但我们不把他们放在接口中。例如，我们的账户可以为余额超过一定限额的用户，提供 10% 的额外积分，但我们不希望用户获取计算细节的访问。我们可以通过以下方式，实现这一功能：


```lua
function newAccount (initialBalance)
    local self = {
        balance = initialBalance,
        LIM = 10000.00,
    }

    local extra = function ()
        if self.balance > self.LIM then
            return self.balance*0.10
        else
            return 0
        end
    end
    
    local getBalance = function () 
        return self.balance + extra()
    end

    -- 照旧
end
```


同样，任何用户都无法直接访问这个 `extra` 函数。

> **译注**：下面的代码，演示了这种模式下，一个公开函数对另一公开函数的访问（与对私有函数的访问类似，被调用的公开函数前不带 `self`）。


```lua
function newAccount (initialBalance)
    local self = {
        balance = initialBalance,
        LIM = 10000.00,
    }

    local extra = function ()
        if self.balance > self.LIM then
            return self.balance*0.10
        else
            return 0
        end
    end
    
    local getBalance = function () 
        return self.balance + extra()
    end

    local withdraw = function (v)
                        self.balance = getBalance() -v
                    end

    local deposit = function (v)
                        self.balance = getBalance() + v
                    end



    return {
        withdraw = withdraw,
        deposit = deposit,
        getBalance = getBalance
    }

end
```



## 单一方法方式

**The Single-Method Approach**


当某个对象只有一个方法时，前面这种面向对象编程方式，就会出现一种特殊情况。在这种情况下，我们不需要创建接口表；相反，我们可以返回这个单一方法，作为对象表示，the object representation。如果这听起来有点奇怪，那么我们不妨回忆一下 `io.lines` 或 `string.gmatch` 等迭代器。在内部保持状态的迭代器，正是单一方法的对象。


单一方法对象的另一个有趣情况，就是当这个单一方法实际上是个调度方法，a dispatch method，时，就会根据不同参数，a distinguished argument，执行不同任务。这种对象的原型实现如下所示：


```lua
function newObject (value)
    return function (action, v)
        if action == "get" then return value
        elseif action == "set" then value = v
        else error"无效操作"
        end
    end
end
```


其使用方法简单明了：


```console
$ lua -i lib/single-method_object.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> d = newObject(0)
> d("get")
0
> d("set", 10)
> d("get")
10
```


这种非常规的对象实现方式相当有效。语法 `d("set", 10)` 虽然奇特，但只比常规的 `d:set(10)` 长两个字符。每个对象使用一个闭包，通常比一个表开销更低。虽然没有继承，但我们有着完全的隐私：访问对象状态的仅有途径，是通过其唯一的方法。



## 双重表示


**Dual Representation**


另一种有趣的隐私实现方式，是使用 *双重表示法，dual representation*。我们先来看看什么是双重表示法。

通常，我们使用键，将属性与表关联起来，we associate attributes to tables using keys, 如下所示：


```lua
table[key] = value
```

不过，我们可以使用双重表示法：我们可以使用表来表示键，并将对象本身作为表中的键：

```lua
key = {}

key[table] = value
```

这里的一个关键因素，是我们不仅可以用数字和字符串，还可以用任何值（尤其是其他表），为 Lua 中的表编制索引。


例如，在我们的账户实现中，我们可以将所有账户的余额，保存在一个 `balance` 表中，而不是保存在账户本身中。咱们的 `withdraw` 方法就会变成下面这样：


```lua
function Account.withdraw (self, v)
    balance[self] = balance[self] -v
end
```

这里我们获得了什么？隐私。即使函数可以访问某个账户，也无法直接访问其余额，除非他也可以访问表 `balance`。如果表 `balance` 保存在 `Account` 模块内部的某个本地（变量）中，那么就只有这模块内部的函数才可以访问他，因此也只有这些函数才可以操作账户余额。


在咱们继续之前，我（作者）必须讨论一下这种实现方法的一个很大的天真之处。一旦我们将某个账户作为 `balance` 表中的键，那么这个账户就永远不会成为垃圾回收器的垃圾。他将被固定在那里，直到某些代码显式地将其从那个表中删除。这对于银行账户来说，可能不是问题（因为账户在消失前，通常必须正式关闭），但对于其他情形来说，这就可能是个很大的缺陷。在 [“对象属性”](garbage.md#对象属性) 小节，我们将了解如何解决这个问题。现在，我们先不考虑这个问题。


[图 21.3 “用到双重表示的账户”](#f-21.3) 再次给出了一种账户的实现，这次使用了双重表示法。


<a name="f-21.3">**用到双重表示的账户</a>


```lua
local balance = {}

Account = {}


function Account:withdraw (v)
    balance[self] = balance[self] -v
end

function Account:deposit (v)
    balance[self] = balance[self] + v
end

function Account:balance ()
    return balance[self]
end

function Account:new (o)
    o = o or {}     -- 在用户没有提供表表时，创建出表
    setmetatable(o, self)
    self.__index = self
    balance[o] = 0      -- 初始余额
    return o
end
```

我们就像使用其他类一样，使用这个类：


```console
$ lua -i lib/account.dual-rep.lua
Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio
> a = Account:new{}
> a:balance()
0
> a:deposit(100.00)
> a:balance()
100.0
```

但是，我们不能篡改账户余额，tamper with an account balance。通过保持 `balance` 表对该模块的私有性，这种实现方式确保了他的安全。

继承无需修改即可用。在时间和内存开销方面，这种方式与标准方法非常相似。新对象需要一个新表，以及每个用到的私有表中的一个新条目。访问 `balance[self]` 可能比访问 `self.balance` 稍慢，因为后者使用的是本地变量，而前者使用的是外部变量。通常这种差异可以忽略不计。稍后我们将看到，其还需要在垃圾回收器，完成一些额外工作。



## 练习

**Exercises**


练习 21.1：实现一个具有 `push`、`pop`、`top` 和 `isempty` 等方法的 `Stack` 类；

练习 21.2：实现一个作为 `Stack` 子类的 `StackQueue` 类。除了继承的方法外，请在该类中添加一个 `insertbottom` 方法，用以在栈的底部插入一个元素。(此方法允许我们将该类的对象用作队列）；

练习 21.3：请使用双重表示法重新实现咱们的 `Stack` 类；

练习 21.4：双重表示法的一个变种，是使用代理，proxy，来实现对象（名为 [追踪表访问](metatables_and_metamethods.md#追踪表访问) 的小节）。每个对象都由一个空代理表来表示。一张内部表会将代理，映射到承载对象状态的表。这个内部表不能从外部访问，但方法会使用他，来将其 `self` 参数转换到他们所操作的真实表。请使用这种方法，实现那个银行账户的示例，并讨论其利弊。

