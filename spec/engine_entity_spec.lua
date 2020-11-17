local lovetoys = require('')
lovetoys.initialize()

describe('Engine', function()
    local TestSystem, MultiSystem
    local Component1, Component2
    local entity, entity2, entity3
    local testSystem, multiSystem, engine

    setup(
    function()
        TestSystem = lovetoys.Class('TestSystem', lovetoys.System)
        function TestSystem:Requires()
            return {'Component1'}
        end

        -- Creates a System with multiple requirements
        MultiSystem = lovetoys.Class('MultiSystem', lovetoys.System)
        function MultiSystem:Requires()
            return {name1 = {'Component1'}, name2 = {'Component1', 'Component2'}}
        end

        Component1 = lovetoys.Component.Create('Component1')
        Component2 = lovetoys.Component.Create('Component2')
    end
    )

    before_each(
    function()
        entity = lovetoys.Entity()
        entity2 = lovetoys.Entity()
        entity3 = lovetoys.Entity()

        testSystem = TestSystem()
        engine = lovetoys.Engine()
        multiSystem = MultiSystem()
    end
    )

    it(':AddEntity() gives entity an id', function()
        engine:AddEntity(entity)
        assert.are.equal(entity.id, 1)
    end)

    it(':AddEntity() sets self.rootEntity as parent', function()
        engine:AddEntity(entity)
        assert.are.equal(engine.rootEntity, entity.parent)
    end)

    it(':AddEntity() registers entity in self.rootEntity.children', function()
        engine:AddEntity(entity)
        assert.are.equal(engine.rootEntity.children[1], entity)
    end)

    it(':AddEntity() sets custom parent', function()
        engine:AddEntity(entity)
        entity2.parent = entity
        engine:AddEntity(entity2)
        assert.are.equal(entity.children[2], entity2)
    end)

    it(':AddEntity() adds entity to componentlist', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        assert.are.equal(engine:GetEntitiesWithComponent('Component1')[1], entity)
    end)

    it(':AddEntity() adds entity to system, before system is added', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(testSystem)
        assert.are.equal(testSystem.targets[1], entity)
    end)

    it(':AddEntity() adds entity to system, after system is added', function()
        engine:AddSystem(testSystem)
        entity:Add(Component1())
        engine:AddEntity(entity)
        assert.are.equal(testSystem.targets[1], entity)
    end)

    it(':Add() adds entity to system, after Component is added to entity', function()
        engine:AddEntity(entity)
        engine:AddSystem(testSystem)
        entity:Add(Component1())
        assert.are.equal(testSystem.targets[1], entity)
    end)

    it(':AddEntity() adds entity to system, after Component is added to system', function()
        engine:AddEntity(entity)
        engine:AddSystem(testSystem)
        entity:Add(Component1())
        assert.are.equal(testSystem.targets[1], entity)
    end)

    it(':GetEntityCount() gets count of entities with Component, after Component is added to entities', function()
        entity:Add(Component1())
        entity2:Add(Component1())
        engine:AddEntity(entity)
        engine:AddEntity(entity2)
        assert.are.equal(engine:GetEntityCount('Component1'), 2)
    end)

    it(':AddEntity() handles multiple requirement lists', function()
        local function count(t)
            local c = 0
            for _, _ in pairs(t) do
                c = c + 1
            end
            return c
        end

        local Animal, Dog = lovetoys.Component.Create('Animal'), lovetoys.Component.Create('Dog')

        local AnimalSystem = lovetoys.Class('AnimalSystem', lovetoys.System)

        function AnimalSystem:Update() end

        function AnimalSystem:Requires()
            return {animals = {'Animal'}, dogs = {'Dog'}}
        end

        local animalSystem = AnimalSystem()
        engine:AddSystem(animalSystem)

        entity:Add(Animal())

        entity2:Add(Animal())
        entity2:Add(Dog())

        engine:AddEntity(entity)
        engine:AddEntity(entity2)

        assert.are.equal(count(animalSystem.targets.animals), 2)
        assert.are.equal(count(animalSystem.targets.dogs), 1)

        entity2:Remove('Dog')
        assert.are.equal(count(animalSystem.targets.animals), 2)
        assert.are.equal(count(animalSystem.targets.dogs), 0)

        entity:Add(Dog())
        assert.are.equal(count(animalSystem.targets.animals), 2)
        assert.are.equal(count(animalSystem.targets.dogs), 1)
    end)

    it(':RemoveEntity() removes a single', function()
        engine:AddEntity(entity)
        assert.are.equal(engine.rootEntity.children[1], entity)
        engine:RemoveEntity(entity)
        assert.are_not.equal(engine.rootEntity.children[1], entity)
    end)

    it(':RemoveEntity() removes entity from Parent', function()
        engine:AddEntity(entity)
        assert.are.equal(engine.rootEntity.children[1], entity)
        engine:RemoveEntity(entity)
        assert.are_not.equal(engine.rootEntity.children[1], entity)
    end)

    it(':RemoveEntity() sets rootEntity as new parent/ registers as child', function()
        engine:AddEntity(entity)
        entity2.parent = entity
        engine:AddEntity(entity2)
        assert.are.equal(entity.children[2], entity2)
        engine:RemoveEntity(entity)
        assert.are.equal(engine.rootEntity.children[2], entity2)
        assert.are.equal(engine.rootEntity, entity2.parent)
    end)

    it(':RemoveEntity() sets rootEntity as new parent', function()
        engine:AddEntity(entity)
        entity2.parent = entity
        engine:AddEntity(entity2)
        assert.are.equal(entity.children[2], entity2)
        engine:RemoveEntity(entity)
        assert.are.equal(engine.rootEntity.children[2], entity2)
    end)

    it(':RemoveEntity() deletes children', function()
        engine:AddEntity(entity)
        entity2.parent = entity
        engine:AddEntity(entity2)
        assert.are.equal(entity.children[2], entity2)
        engine:RemoveEntity(entity, true)
        assert.are.equal(engine.entities[1], nil)
        assert.are.equal(engine.entities[2], nil)
    end)

    it(':RemoveEntity() sets custom parent', function()
        engine:AddEntity(entity)
        entity2.parent = entity
        engine:AddEntity(entity2)
        assert.are.equal(entity.children[2], entity2)
        engine:RemoveEntity(entity, false, entity3)
        assert.are.equal(entity3.children[2], entity2)
        assert.are.equal(entity3, entity2.parent)
    end)

    it(':RemoveEntity() removes from componentlist', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        assert.are.equal(engine:GetEntitiesWithComponent('Component1')[1], entity)
        engine:RemoveEntity(entity)
        assert.are_not.equal(engine:GetEntitiesWithComponent('Component1')[1], entity)
    end)

    it(':RemoveEntity() removes from System', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(testSystem)
        assert.are.equal(testSystem.targets[1], entity)
        engine:RemoveEntity(entity)
        assert.are_not.equal(testSystem.targets[1], entity)
    end)

    it(':RemoveEntity() unregistered entity from Engine', function()
        -- Mock lovetoys debug function
        local debug_spy = spy.on(lovetoys, 'debug')

        -- Add Component to entity and remove entity from engine
        -- before it's registered to the engine.
        entity:Add(Component1())
        engine:RemoveEntity(entity)

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        entity.id = 1
        engine:RemoveEntity(entity)
        assert.spy(debug_spy).was_called()

        lovetoys.debug:revert()
    end)

    it('Entity:Remove() removes entity from single system target list, after removing component', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(testSystem)
        assert.are.equal(testSystem.targets[1], entity)

        entity:Remove('Component1')
        assert.are_not.equal(testSystem.targets[1], entity)
    end)

    it('Entity:Remove() removes entity from system, after removing component', function()
        entity:Add(Component1())
        entity:Add(Component2())
        engine:AddEntity(entity)
        engine:AddSystem(multiSystem)
        assert.are.equal(multiSystem.targets['name1'][1], entity)
        assert.are.equal(multiSystem.targets['name2'][1], entity)

        entity:Remove('Component2')
        assert.are.equal(multiSystem.targets['name1'][1], entity)
        assert.True(#multiSystem.targets['name2'] == 0)
    end)

    it('Entity:Remove() removes entity from system with multiple requirements', function()
        entity:Add(Component1())
        entity:Add(Component2())
        engine:AddEntity(entity)
        engine:AddSystem(multiSystem)
        assert.are.equal(multiSystem.targets['name1'][1], entity)
        assert.are.equal(multiSystem.targets['name2'][1], entity)

        engine:RemoveEntity(entity)
        assert.True(#multiSystem.targets['name1'] == 0)
        assert.True(#multiSystem.targets['name2'] == 0)
    end)


    it(':GetRootEntity() gets rootEntity', function()
        assert.are.equal(engine:GetRootEntity(), engine.rootEntity)
    end)
end)
