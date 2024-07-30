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
