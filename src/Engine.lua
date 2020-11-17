--- Getting folder that contains our src
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

local lovetoys = require(folderOfThisFile .. 'namespace')
---@class Engine:class
local Engine = lovetoys.class("Engine")

---@alias EntityList table<string, table<string, Entity>>

function Engine:Initialize()
    self.entities = {}
    -- Root Entity of the entity tree
    self.rootEntity = lovetoys.Entity()
    self.singleRequirements = {}
    self.allRequirements = {}
    ---@type EntityList
    self.entityLists = {}
    self.eventManager = lovetoys.EventManager()

    self.systems = {}
    self.systemRegistry = {}
    self.systems["update"] = {}
    self.systems["draw"] = {}

    self.eventManager:AddListener("ComponentRemoved", self, self.componentRemoved)
    self.eventManager:AddListener("ComponentAdded", self, self.componentAdded)
end

---@param entity Entity
function Engine:AddEntity(entity)
    -- Setting engine eventManager as eventManager for entity
    entity.eventManager = self.eventManager
    -- Getting the next free ID or insert into table
    local newId = #self.entities + 1
    entity.id = newId
    self.entities[entity.id] = entity

    -- If a rootEntity entity is defined and the entity doesn't have a parent yet, the rootEntity entity becomes the entity's parent
    if entity.parent == nil then
        entity:SetParent(self.rootEntity)
    end
    entity:RegisterAsChild()

    for _, component in pairs(entity.components) do
        local name = component.class.name
        -- Adding Entity to specific Entitylist
        if not self.entityLists[name] then self.entityLists[name] = {} end
        self.entityLists[name][entity.id] = entity

        -- Adding Entity to System if all requirements are granted
        if self.singleRequirements[name] then
            for _, system in pairs(self.singleRequirements[name]) do
                self:checkRequirements(entity, system)
            end
        end
    end
end

---@param entity Entity
---@param removeChildren boolean
---@param newParent Entity
function Engine:RemoveEntity(entity, removeChildren, newParent)
    if self.entities[entity.id] then
        -- Removing the Entity from all Systems and engine
        for _, component in pairs(entity.components) do
            local name = component.class.name
            if self.singleRequirements[name] then
                for _, system in pairs(self.singleRequirements[name]) do
                    system:RemoveEntity(entity)
                end
            end
        end
        -- Deleting the Entity from the specific entity lists
        for _, component in pairs(entity.components) do
            self.entityLists[component.class.name][entity.id] = nil
        end

        -- If removeChild is defined, all children become deleted recursively
        if removeChildren then
            for _, child in pairs(entity.children) do
                self:RemoveEntity(child, true)
            end
        else
            -- If a new Parent is defined, this Entity will be set as the new Parent
            for _, child in pairs(entity.children) do
                if newParent then
                    child:SetParent(newParent)
                else
                    child:SetParent(self.rootEntity)
                end
                -- Registering as child
                entity:RegisterAsChild()
            end
        end
        -- Removing Reference to entity from parent
        for _, _ in pairs(entity.parent.children) do
            entity.parent.children[entity.id] = nil
        end
        -- Setting status of entity to dead. This is for other systems, which still got a hard reference on this
        self.entities[entity.id].alive = false
        -- Removing entity from engine
        self.entities[entity.id] = nil
    else
        lovetoys.debug("Engine: Trying to remove non existent entity from engine.")
        if entity.id then
            lovetoys.debug("Engine: Entity id: " .. entity.id)
        else
            lovetoys.debug("Engine: Entity has not been added to any engine yet. (No entity.id)")
        end
        lovetoys.debug("Engine: Entity's components:")
        for index, component in pairs(entity.components) do
            lovetoys.debug(index, component)
        end
    end
end

local function SystemTypeContains(systemType, check)
    if systemType == check then
        return true
    elseif type(systemType) == "table" then
        for i,v in pairs(systemType) do
            if v == check then
                return true
            end
        end
    end
    return false
end

---@param system System
---@param type string
---@return System
function Engine:AddSystem(system, type)
    local name = system.class.name

    -- Check if the user is accidentally adding two instances instead of one
    if self.systemRegistry[name] and self.systemRegistry[name] ~= system then
        lovetoys.debug("Engine: Trying to add two different instances of the same system. Aborting.")
        return
    end

    -- Adding System to engine system reference table
    if not (self.systemRegistry[name]) then
        self:registerSystem(system)
    -- This triggers if the system doesn't have update and draw and it's already existing.
    elseif not (system.update and system.draw) then
        if self.systemRegistry[name] then
            lovetoys.debug("Engine: System " .. name .. " already exists. Aborting")
            return
        end
    end

    -- Adding System to draw table
    if system.draw and (not type or SystemTypeContains(type, "draw")) then
        for _, registeredSystem in pairs(self.systems["draw"]) do
            if registeredSystem.class.name == name then
                lovetoys.debug("Engine: System " .. name .. " already exists. Aborting")
                return
            end
        end
        table.insert(self.systems["draw"], system)
    -- Adding System to update table
    end
    if system.update and (not type or SystemTypeContains(type, "update")) then
        for _, registeredSystem in pairs(self.systems["update"]) do
            if registeredSystem.class.name == name then
                lovetoys.debug("Engine: System " .. name .. " already exists. Aborting")
                return
            end
        end
        table.insert(self.systems["update"], system)
    end

    -- Checks if some of the already existing entities match the required components.
    for _, entity in pairs(self.entities) do
        self:checkRequirements(entity, system)
    end
    return system
end

---@param system System
function Engine:registerSystem(system)
    local name = system.class.name
    self.systemRegistry[name] = system
    system.engine = self
    -- case: system:Requires() returns a table of strings
    if not system.hasGroups then
        for index, req in pairs(system:Requires()) do
            -- Registering at singleRequirements
            if index == 1 then
                self.singleRequirements[req] = self.singleRequirements[req] or {}
                table.insert(self.singleRequirements[req], system)
            end
            -- Registering at allRequirements
            self.allRequirements[req] = self.allRequirements[req] or {}
            table.insert(self.allRequirements[req], system)
        end
    end

    -- case: system:Requires() returns a table of tables which contain strings
    if system.hasGroups then
        for group, componentList in pairs(system:Requires()) do
            -- Registering at singleRequirements
            local component = componentList[1]
            self.singleRequirements[component] = self.singleRequirements[component] or {}
            table.insert(self.singleRequirements[component], system)

            -- Registering at allRequirements
            for _, req in pairs(componentList) do
                self.allRequirements[req] = self.allRequirements[req] or {}
                -- Check if this List already contains the System
                local contained = false
                for _, registeredSystem in pairs(self.allRequirements[req]) do
                    if registeredSystem == system then
                        contained = true
                        break
                    end
                end
                if not contained then
                    table.insert(self.allRequirements[req], system)
                end
            end
        end
    end
end

---@param name string
function Engine:stopSystem(name)
    if self.systemRegistry[name] then
        self.systemRegistry[name].active = false
    else
        lovetoys.debug("Engine: Trying to stop not existing System: " .. name)
    end
end

---@param name string
function Engine:startSystem(name)
    if self.systemRegistry[name] then
        self.systemRegistry[name].active = true
    else
        lovetoys.debug("Engine: Trying to start not existing System: " .. name)
    end
end

---@param name string
function Engine:toggleSystem(name)
    if self.systemRegistry[name] then
        self.systemRegistry[name].active = not self.systemRegistry[name].active
    else
        lovetoys.debug("Engine: Trying to toggle not existing System: " .. name)
    end
end

---@param name string
---@return System
function Engine:GetSystem(name)
    return self.systemRegistry[name]
end

---@param dt number Deltatime
function Engine:update(dt)
    for _, system in ipairs(self.systems["update"]) do
        if system.active then
            system:update(dt)
        end
    end
end

function Engine:draw()
    for _, system in ipairs(self.systems["draw"]) do
        if system.active then
            system:draw()
        end
    end
end

---@param event Event
function Engine:ComponentRemoved(event)
    -- In case a single component gets removed from an entity, we inform
    -- all systems that this entity lost this specific component.
    local entity = event.entity
    local component = event.component

    -- Removing Entity from Entity lists
    self.entityLists[component][entity.id] = nil

    -- Removing Entity from systems
    if self.allRequirements[component] then
        for _, system in pairs(self.allRequirements[component]) do
            system:ComponentRemoved(entity, component)
        end
    end
end

---@param event Event
function Engine:ComponentAdded(event)
    local entity = event.entity
    local component = event.component

    -- Adding the Entity to Entitylist
    if not self.entityLists[component] then self.entityLists[component] = {} end
    self.entityLists[component][entity.id] = entity

    -- Adding the Entity to the requiring systems
    if self.allRequirements[component] then
        for _, system in pairs(self.allRequirements[component]) do
            self:checkRequirements(entity, system)
        end
    end
end

function Engine:GetRootEntity()
    if self.rootEntity ~= nil then
        return self.rootEntity
    end
end

--- Returns an Entitylist for a specific component. If the Entitylist doesn't exist yet it'll be created and returned.
---@param component Component
---@return EntityList
function Engine:GetEntitiesWithComponent(component)
    if not self.entityLists[component] then self.entityLists[component] = {} end
    return self.entityLists[component]
end

--- Returns a count of existing Entities with a given component
---@param component Component
---@return integer
function Engine:GetEntityCount(component)
    local count = 0
    if self.entityLists[component] then
        for _, system in pairs(self.entityLists[component]) do
            count = count + 1
        end
    end
    return count
end

---@param entity Entity
---@param system System
function Engine:checkRequirements(entity, system) -- luacheck: ignore self
    local meetsRequirements = true
    local foundGroup = nil
    for group, req in pairs(system:Requires()) do
        if not system.hasGroups then
            if not entity.components[req] then
                meetsRequirements = false
                break
            end
        else
            meetsRequirements = true
            for _, req2 in pairs(req) do
                if not entity.components[req2] then
                    meetsRequirements = false
                    break
                end
            end
            if meetsRequirements == true then
                foundGroup = true
                system:AddEntity(entity, group)
            end
        end
    end
    if meetsRequirements == true and foundGroup == nil then
        system:AddEntity(entity)
    end
end

return Engine
