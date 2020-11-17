require('')()
local luatrace = require('luatrace.profile')

luatrace.tron()

local components = {}
for i = 0, 5, 1 do
  table.insert(components, Component.Create('TestComponent'..i))
end

local SmallSystem = class('System', System)
function SmallSystem:update()
  local lol = 1 + 1
end

function SmallSystem:Requires()
  return {'TestComponent'}
end

local BigSystem = class('System', System)
function BigSystem:update()
  local lol = 1 + 1
end

local names = {}
for k,component in pairs(components) do
  table.insert(names, component.class.name)
end

function BigSystem:Requires()
  return names
end

local engine = Engine()

engine:AddSystem(SmallSystem())
engine:AddSystem(BigSystem())

local smallEntity = Entity()

smallEntity:Add(components[1]())

local bigEntity = Entity()

for k,v in pairs(components) do
  bigEntity:Add(v())
end

engine:AddEntity(smallEntity)

engine:AddEntity(bigEntity)

engine:update(0.1)

engine:RemoveEntity(smallEntity)

engine:RemoveEntity(bigEntity)

luatrace.troff()
