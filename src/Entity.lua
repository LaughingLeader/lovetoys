--- Getting folder that contains our src
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

---@type lovetoys
local lovetoys = require(folderOfThisFile .. 'namespace')
---@class Entity:class
local Entity = lovetoys.Class("Entity")

---@param name string
---@param parent Entity
function Entity:Initialize(name, parent)
    ---@type table<string, Component>
    self.components = {}
    ---@type EventManager
    self.eventManager = nil
    self.alive = false
    if parent then
        self:SetParent(parent)
    else
        parent = nil
    end
    self.name = name
    self.children = {}

    if self.OnInit ~= nil then
        self:OnInit()
    end
end

--- Sets the entities component of this type to the given component.
--- An entity can only have one Component of each type.
---@param component Component
function Entity:Add(component)
    local name = component.name
    if component.class ~= nil then
        name = component.class.name
    else
        lovetoys.debug("Component .class field of '" .. name .. "' is nil!")
    end
    if self.components[name] then
        lovetoys.debug("Entity: Trying to add Component '" .. name .. "', but it's already existing. Please use Entity:Set to overwrite a component in an entity.")
    else
        self.components[name] = component
        if self.eventManager then
            self.eventManager:FireEvent(lovetoys.ComponentAdded(self, name))
        end
    end
end

---@param component Component
function Entity:Set(component)
    local name = component.class.name
    if self.components[name] == nil then
        self:Add(component)
    else
        self.components[name] = component
    end
end

---@param componentList Component[]
function Entity:AddMultiple(componentList)
    for _, component in  pairs(componentList) do
        self:Add(component)
    end
end

--- Removes a component from the entity.
---@param name string
function Entity:Remove(name)
    if self.components[name] then
        self.components[name] = nil
    else
        lovetoys.debug("Entity: Trying to remove non-existent component " .. name .. " from Entity. Please fix this")
    end
    if self.eventManager then
        self.eventManager:FireEvent(lovetoys.ComponentRemoved(self, name))
    end
end

---@param parent Entity
function Entity:SetParent(parent)
    if self.parent then self.parent.children[self.id] = nil end
    self.parent = parent
    self:RegisterAsChild()
end

---@return Entity
function Entity:GetParent()
    return self.parent
end

function Entity:RegisterAsChild()
    if self.id then self.parent.children[self.id] = self end
end

---@param name string
---@return Component
function Entity:Get(name)
    return self.components[name]
end

--- Retrieve a value nested in a component,
--- specified by a path separated by dots:
--- <component name>.<property>.<property>...
---@param path string
---@return Component|nil
function Entity:GetPath(path)
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
function Entity:GetMultiple(...)
    local res = {}
    for _, component in pairs{...} do
        table.insert(res, self.components[component])
    end
    return unpack(res)
end

---@param name string
---@return boolean
function Entity:Has(name)
    return not not self.components[name]
end

---@return table<string, Component>
function Entity:GetComponents()
    return self.components
end

return Entity
