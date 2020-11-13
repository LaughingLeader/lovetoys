--- Getting folder that contains our src
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

local lovetoys = require(folderOfThisFile .. 'namespace')
---@class Entity:class
local Entity = lovetoys.class("Entity")

---@param parent Entity
---@param name string
function Entity:initialize(parent, name)
    ---@type table<string, Component>
    self.components = {}
    ---@type EventManager
    self.eventManager = nil
    self.alive = false
    if parent then
        self:setParent(parent)
    else
        parent = nil
    end
    self.name = name
    self.children = {}
end

--- Sets the entities component of this type to the given component.
--- An entity can only have one Component of each type.
---@param component Component
function Entity:add(component)
    local name = component.class.name
    if self.components[name] then
        lovetoys.debug("Entity: Trying to add Component '" .. name .. "', but it's already existing. Please use Entity:set to overwrite a component in an entity.")
    else
        self.components[name] = component
        if self.eventManager then
            self.eventManager:fireEvent(lovetoys.ComponentAdded(self, name))
        end
    end
end

---@param component Component
function Entity:set(component)
    local name = component.class.name
    if self.components[name] == nil then
        self:add(component)
    else
        self.components[name] = component
    end
end

---@param componentList Component[]
function Entity:addMultiple(componentList)
    for _, component in  pairs(componentList) do
        self:add(component)
    end
end

--- Removes a component from the entity.
---@param name string
function Entity:remove(name)
    if self.components[name] then
        self.components[name] = nil
    else
        lovetoys.debug("Entity: Trying to remove non-existent component " .. name .. " from Entity. Please fix this")
    end
    if self.eventManager then
        self.eventManager:fireEvent(lovetoys.ComponentRemoved(self, name))
    end
end

---@param parent Entity
function Entity:setParent(parent)
    if self.parent then self.parent.children[self.id] = nil end
    self.parent = parent
    self:registerAsChild()
end

---@return Entity
function Entity:getParent()
    return self.parent
end

function Entity:registerAsChild()
    if self.id then self.parent.children[self.id] = self end
end

---@param name string
---@return Component
function Entity:get(name)
    return self.components[name]
end

--- Retrieve a value nested in a component,
--- specified by a path separated by dots:
--- <component name>.<property>.<property>...
---@param path string
---@return Component|nil
function Entity:getPath(path)
    local result = self.components
    for str in string.gmatch(path, "([^%.]+)") do
        if result[str] then
            result = result[str]
        else
            return nil
        end
    end
    return result
end

---@param names string[]|varargs
---@return Component[]
function Entity:getMultiple(...)
    local res = {}
    for _, component in pairs{...} do
        table.insert(res, self.components[component])
    end
    return unpack(res)
end

---@param name string
---@return boolean
function Entity:has(name)
    return not not self.components[name]
end

---@return table<string, Component>
function Entity:getComponents()
    return self.components
end

return Entity
