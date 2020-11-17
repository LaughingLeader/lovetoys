local lovetoys = require('')
lovetoys.initialize({ debugging = true })

describe('Entity', function()
    local TestComponent, TestComponent1, TestComponent2, TestComponent3
    local entity, entity1, parent
    local testSystem

    setup(
    function()
        TestComponent = lovetoys.Component.Create('TestComponent')
        TestComponent1 = lovetoys.Component.Create('TestComponent1')
        TestComponent2 = lovetoys.Component.Create('TestComponent2')
        TestComponent3 = lovetoys.Component.Create('TestComponent3')
    end
    )

    before_each(
    function()
        entity = lovetoys.Entity()
        entity.id = 1
        entity1 = lovetoys.Entity()
        entity1.id = 2
        parent = lovetoys.Entity()
        testComponent = TestComponent()
        testComponent1 = TestComponent1()
        testComponent2 = TestComponent2()
        testComponent3 = TestComponent3()
    end
    )

    it(':Add() adds a Component', function()
        entity:Add(testComponent)
        assert.are.equal(entity.components[testComponent.class.name], testComponent)
    end)

    it(':Add() doesn`t add the same Component twice', function()
        testComponent.int = 12
        entity:Add(testComponent)
        assert.are.equal(entity.components[testComponent.class.name].int, 12)
        -- Creation of new testComponent with varying variables
        testComponent = TestComponent()
        testComponent.int = 13
        entity:Add(testComponent)
        assert.are_not.equal(entity.components[testComponent.class.name].int, 13)
    end)

    it(':Remove() removes a Component', function()
        entity:Add(testComponent)
        entity:Remove('TestComponent')
    end)

    it(':Remove() prints debug message if Component does not exist', function()
        local debug_spy = spy.on(lovetoys, 'debug')
        entity:Remove('TestComponent')
        assert.spy(debug_spy).was_called()
        lovetoys.debug:revert()
    end)

    it(':Get() gets a Component', function()
        entity:Add(testComponent)
        assert.are.equal(entity:Get(testComponent.class.name), testComponent)
    end)

    it(':GetComponents() gets all components of an entity', function()
        entity:Add(testComponent)
        entity:Add(testComponent1)
        components = entity:GetComponents()

        local count = 0
        for _, __ in pairs(components) do
            count = count + 1
        end

        assert.True(count == 2)
    end)

    it(':Has() shows if it has a Component', function()
        entity:Add(testComponent)
        assert.is_true(entity:Has(testComponent.class.name))
    end)

    it(':Set() adds and overwrites Components', function()
        testComponent.int = 12
        entity:Set(testComponent)
        assert.are.equal(entity.components[testComponent.class.name].int, 12)
        testComponent = TestComponent()
        testComponent.int = 13
        entity:Set(testComponent)
        assert.are.equal(entity.components[testComponent.class.name].int, 13)
    end)

    it(':AddMultiple() adds Multiple Components at once', function()
        local componentList = {testComponent1, testComponent2, testComponent3}
        entity:AddMultiple(componentList)
        assert.are.equal(entity.components[testComponent1.class.name], testComponent1)
        assert.are.equal(entity.components[testComponent2.class.name], testComponent2)
        assert.are.equal(entity.components[testComponent3.class.name], testComponent3)
    end)

    it('Constructor with parrent adds a Parent', function()
        entity = lovetoys.Entity(parent)
        assert.are.equal(entity.parent, parent)
    end)

    it(':SetParent() adds a Parent', function()
        entity:SetParent(parent)
        assert.are.equal(entity.parent, parent)
    end)

    it(':GetParent() gets a Parent', function()
        entity:SetParent(parent)
        assert.are.equal(entity:GetParent(), parent)
    end)

    it(':RegisterAsChild() registers as a Child', function()
        entity:SetParent(parent)
        assert.are.equal(entity:GetParent().children[entity.id], entity)
    end)
end)
