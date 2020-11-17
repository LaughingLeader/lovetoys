local lovetoys = require('')
lovetoys.initialize()

describe('Engine', function()
    local UpdateSystem, DrawSystem, MultiSystem, Component1, Component2
    local entity, entity2, entity3
    local testSystem, engine

    setup(function()
        -- Creates a Update System
        UpdateSystem = lovetoys.Class('UpdateSystem', lovetoys.System)
        function UpdateSystem:Initialize()
            lovetoys.System.initialize(self)
            self.entitiesAdded = 0
        end
        function UpdateSystem:Requires()
            return {'Component1'}
        end
        function UpdateSystem:Update()
            for _, entity in pairs(self.targets) do
                entity:Get('Component1').number = entity:Get('Component1').number + 5
            end
        end

        function UpdateSystem:OnAddEntity()
            self.entitiesAdded = self.entitiesAdded + 1
        end

        -- Creates a Draw System
        DrawSystem = lovetoys.Class('DrawSystem', lovetoys.System)
        function DrawSystem:Requires()
            return {'Component1'}
        end

        function DrawSystem:Draw()
            for _, entity in pairs(self.targets) do
                entity:Get('Component1').number = entity:Get('Component1').number + 10
            end
        end

        -- Creates a system with update and draw function
        BothSystem = lovetoys.Class('BothSystem', lovetoys.System)
        function BothSystem:Requires()
            return {'Component1', 'Component2'}
        end
        function BothSystem:Update()
            for _, entity in pairs(self.targets) do
                entity:Get('Component1').number = entity:Get('Component1').number + 5
            end
        end
        function BothSystem:Draw() end

        -- Creates a System with multiple requirements
        MultiSystem = lovetoys.Class('MultiSystem', lovetoys.System)
        function MultiSystem:Requires()
            return {name1 = {'Component1'}, name2 = {'Component2'}}
        end

        Component1 = lovetoys.Component.Create('Component1')
        Component1.number = 1
        Component2 = lovetoys.Component.Create('Component2')
        Component2.number = 2
    end)

    before_each(function()
        entity = lovetoys.Entity()
        entity2 = lovetoys.Entity()
        entity3 = lovetoys.Entity()

        updateSystem = UpdateSystem()
        drawSystem = DrawSystem()
        bothSystem = BothSystem()
        multiSystem2 = MultiSystem()
        engine = lovetoys.Engine()
    end)

    it(':AddSystem() adds update Systems', function()
        engine:AddSystem(updateSystem)
        assert.are.equal(engine.systems['update'][1], updateSystem)
    end)

    it(':AddSystem() adds System to systemRegistry', function()
        engine:AddSystem(updateSystem)
        assert.are.equal(engine.systemRegistry[updateSystem.class.name], updateSystem)
    end)

    it(':AddSystem() doesn`t add same system type twice', function()
        engine:AddSystem(updateSystem)
        local newUpdateSystem = UpdateSystem()
        engine:AddSystem(newUpdateSystem)
        assert.are.equal(engine.systems['update'][1], updateSystem)
        assert.are.equal(engine.systemRegistry[updateSystem.class.name], updateSystem)
    end)

    it(':AddSystem() adds draw Systems', function()
        engine:AddSystem(drawSystem)
        assert.are.equal(engine.systems['draw'][1], drawSystem)
    end)

    it(':AddSystem() doesn`t add Systems with both, but does, if specified with type', function()
        engine:AddSystem(bothSystem)
        assert.are_not.equal(engine.systems['draw'][1], bothSystem)
        assert.are_not.equal(engine.systems['update'][1], bothSystem)

        engine:AddSystem(bothSystem, 'draw')
        engine:AddSystem(bothSystem, 'update')
        assert.are.equal(engine.systems['draw'][1], bothSystem)
        assert.are.equal(engine.systems['update'][1], bothSystem)
    end)

    it(':AddSystem() adds BothSystem to singleRequirements, if specified with type', function()
        engine:AddSystem(bothSystem)
        assert.are_not.equal(type(engine.singleRequirements['Component1']), 'table')
        assert.are_not.equal(type(engine.singleRequirements['Component2']), 'table')

        engine:AddSystem(bothSystem, 'draw')
        assert.are.equal(engine.singleRequirements['Component1'][1], bothSystem)
        assert.are_not.equal(type(engine.singleRequirements['Component2']), 'table')
    end)

    it(':AddSystem() adds BothSystem to singleRequirements, if specified with type', function()
        engine:AddSystem(bothSystem)
        assert.are_not.equal(type(engine.allRequirements['Component1']), 'table')
        assert.are_not.equal(type(engine.allRequirements['Component2']), 'table')

        engine:AddSystem(bothSystem, 'draw')
        assert.are.equal(engine.allRequirements['Component1'][1], bothSystem)
        assert.are.equal(engine.allRequirements['Component2'][1], bothSystem)
    end)


    it(':AddSystem() doesn`t add Systems to requirement lists multiple times', function()
        engine:AddSystem(bothSystem, 'draw')
        engine:AddSystem(bothSystem, 'update')

        assert.are.equal(engine.singleRequirements['Component1'][1], bothSystem)
        assert.are_not.equal(engine.singleRequirements['Component1'][2], bothSystem)
        assert.are_not.equal(type(engine.singleRequirements['Component2']), 'table')

        assert.are.equal(engine.allRequirements['Component1'][1], bothSystem)
        assert.are.equal(engine.allRequirements['Component2'][1], bothSystem)
        assert.are_not.equal(engine.allRequirements['Component1'][2], bothSystem)
        assert.are_not.equal(engine.allRequirements['Component2'][2], bothSystem)
    end)

    it(':AddSystem() doesn`t add Systems to system lists multiple times', function()
        engine:AddSystem(bothSystem, 'draw')
        engine:AddSystem(bothSystem, 'draw')

        engine:AddSystem(bothSystem, 'update')
        engine:AddSystem(bothSystem, 'update')

        assert.are.equal(engine.systems['draw'][1], bothSystem)
        assert.are.equal(engine.systems['update'][1], bothSystem)

        assert.are_not.equal(engine.systems['draw'][2], bothSystem)
        assert.are_not.equal(engine.systems['update'][2], bothSystem)
    end)

    it(':Update() updates Systems', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(updateSystem)
        assert.are.equal(entity:Get('Component1').number, 1)
        engine:Update()
        assert.are.equal(entity:Get('Component1').number, 6)
    end)

    it(':Update() updates Systems', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(drawSystem)
        assert.are.equal(entity:Get('Component1').number, 1)
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 11)
    end)

    it(':Update() updates Systems', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(drawSystem)
        assert.are.equal(entity:Get('Component1').number, 1)
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 11)
    end)

    it(':Stop(), start(), toggle() works', function()
        entity:Add(Component1())
        engine:AddEntity(entity)
        engine:AddSystem(drawSystem)
        assert.are.equal(entity:Get('Component1').number, 1)
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 11)

        engine:StopSystem('DrawSystem')
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 11)

        engine:StartSystem('DrawSystem')
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 21)

        engine:ToggleSystem('DrawSystem')
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 21)

        engine:ToggleSystem('DrawSystem')
        engine:Draw()
        assert.are.equal(entity:Get('Component1').number, 31)
    end)

    it('Calling system status functions on not existing systems throws debug message.', function()
        -- Mock lovetoys debug function
        local debug_spy = spy.on(lovetoys, 'debug')

        engine:StartSystem('weirdstufflol')
        -- Assert that the debug function has been called
        -- and clear spy call history
        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        engine:ToggleSystem('weirdstufflol')
        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        engine:StopSystem('weirdstufflol')
        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        lovetoys.debug:revert()
    end)


    it('calls UpdateSystem:onComponentAdded when a component is added to UpdateSystem', function()
        assert.are.equal(updateSystem.entitiesAdded, 0)

        entity:Add(Component1())
        engine:AddSystem(updateSystem)
        engine:AddEntity(entity)

        assert.are.equal(updateSystem.entitiesAdded, 1)
    end)

    it(':AddSystem(system, "derp") fails', function()
        local debug_spy = spy.on(lovetoys, 'debug')

        engine:AddSystem(drawSystem, 'derp')
        assert.is_nil(engine.systemRegistry['DrawSystem'])

        assert.spy(debug_spy).was_called()
        lovetoys.debug:revert()
    end)

    it('refuses to add two instances of the same system', function()
        local debug_spy = spy.on(lovetoys, 'debug')

        engine:AddSystem(DrawSystem())
        engine:AddSystem(DrawSystem())

        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        engine:AddSystem(BothSystem(), 'update')
        engine:AddSystem(BothSystem(), 'draw')

        assert.spy(debug_spy).was_called()
        lovetoys.debug:revert()
    end)
end)
