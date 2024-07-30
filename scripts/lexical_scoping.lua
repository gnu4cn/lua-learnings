#!/usr/bin/env lua

function digitButton (digit)
    return Button{
        label = tostring(digit),
        action = function ()
            add_to_digits(digit)
        end
    }
end
