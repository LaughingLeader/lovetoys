-- Getting folder that contains our src
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

---@type lovetoys
local lovetoys = require(folderOfThisFile)

print('require(\'lovetoys.lovetoys\') is deprecated. Use require(\'lovetoys\') instead.')

return lovetoys
