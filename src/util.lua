---@class util
local util = {}

function util.FirstElement(list)
    local _, value = next(list)
    return value
end

return util
