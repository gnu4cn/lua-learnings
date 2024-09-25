local results = {}
setmetatable(results, {__mode = "v"})   -- 使值成为弱值
function createRGB (r, g, b)
    local key = string.format("%d-%d-%d", r, g, b)
    local color = results[key]
    if color == nil then
        color = {red = r, green = g, blue = b}
        results[key] = color
    end
    return color
end
