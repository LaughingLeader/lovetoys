-- Getting folder that contains our src
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

local lovetoys = require(folderOfThisFile .. 'namespace')
---@class System:class
local System = lovetoys.class("System")

function System:Initialize()
    ---@type table<string, Entity>|table<string, table<string, Entity>>
    self.targets = {}
    ---@type Engine
    self.engine = nil
    self.active = true
    self.hasGroups = nil
    for group, req in pairs(self:Requires()) do
        local requirementIsGroup = type(req) == "table"
        if self.hasGroups ~= nil then
            assert(self.hasGroups == requirementIsGroup, "System " .. self.class.name .. " has mixed requirements in requires()")
        else
            self.hasGroups = requirementIsGroup
        end

        if requirementIsGroup then
            self.targets[group] = {}
        end
    end
end

function System:Requires() return {} end

function System:OnAddEntity(entity, group) end

function System:OnRemoveEntity(entity, group) end

function System:AddEntity(entity, category)
    -- If there are multiple requirement lists, the added entities will
    -- be added to their respective list.
    if category then
        self.targets[category][entity.id] = entity
    else
        -- Otherwise they'll be added to the normal self.targets list
        self.targets[entity.id] = entity
    end

    self:OnAddEntity(entity, category)
end

function System:RemoveEntity(entity, group)
    if group and self.targets[group][entity.id] then
        self.targets[group][entity.id] = nil
        self:OnRemoveEntity(entity, group)
        return
    end

    local firstGroup, _ = next(self.targets)
    if firstGroup then
        if self.hasGroups then
            -- Removing entities from their respective category target list.
            for group, _ in pairs(self.targets) do
                if self.targets[group][entity.id] then
                    self.targets[group][entity.id] = nil
                    self:OnRemoveEntity(entity, group)
                end
            end
        else
            if self.targets[entity.id] then
                self.targets[entity.id] = nil
                self:OnRemoveEntity(entity)
            end
        end
    end
end

function System:ComponentRemoved(entity, component)
    if self.hasGroups then
        -- Removing entities from their respective category target list.
        for group, requirements in pairs(self:Requires()) do
            for _, req in pairs(requirements) do
                if req == component then
                    self:RemoveEntity(entity, group)
                    -- stop checking requirements for this group
                    break
                end
            end
        end
    else
        self:RemoveEntity(entity)
    end
end

function System:PickRequiredComponents(entity)
    local components = {}
    local requirements = self:Requires()

    if type(lovetoys.util.FirstElement(requirements)) == "string" then
        for _, componentName in pairs(requirements) do
            table.insert(components, entity:Get(componentName))
        end
    elseif type(lovetoys.util.FirstElement(requirements)) == "table" then
        lovetoys.debug("System: :PickRequiredComponents() is not supported for systems with multiple component constellations")
        return nil
    end
    return unpack(components)
end

function System:GetEntitiesWithName(name)
    local entities = {}
    if not self.hasGroups then
        for k,v in pairs(self.targets) do
            if v.name == name then
                table.insert(entities, v)
            end
        end
    else
        for groupName,group in pairs(self.targets) do
            for k,v in pairs(group) do
                if v.name == name then
                    table.insert(entities, v)
                end
            end
        end
    end
    return entities
end

return System
