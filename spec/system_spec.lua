local lovetoys = require('')
lovetoys.Initialize()

describe('System', function()
    local MultiSystem, RequireSystem
    local entity, entity1, entity2
    local multiSystem, engine

    setup(
      function()
          MultiSystem = lovetoys.Class('MultiSystem', lovetoys.System)
          function MultiSystem:Requires()
              return {ComponentType1 = {'Component1'}, ComponentType2 = {'Component'}}
          end

          RequireSystem = lovetoys.Class('RequireSystem', lovetoys.System)
          function RequireSystem:Requires()
              return {'Component1', 'Component2'}
          end
      end
    )

    before_each(
      function()
          entity = lovetoys.Entity()
          entity.id = 1
          entity1 = lovetoys.Entity()
          entity1.id = 1
          entity2 = lovetoys.Entity()
          entity2.id = 2

          multiSystem = MultiSystem()
          requireSystem = RequireSystem()
          engine = lovetoys.Engine()
      end
    )

    it(':AddEntity() adds single', function()
        multiSystem:AddEntity(entity)

        assert.are.equal(multiSystem.targets[1], entity)
    end)

    it(':AddEntity() adds entities into different categories', function()
        engine:AddSystem(multiSystem)

        multiSystem:AddEntity(entity1, 'ComponentType1')
        multiSystem:AddEntity(entity2, 'ComponentType2')

        assert.are.equal(multiSystem.targets['ComponentType1'][1], entity1)
        assert.are.equal(multiSystem.targets['ComponentType2'][2], entity2)
    end)

    it(':RemoveEntity() removes single', function()
        multiSystem:AddEntity(entity, 'ComponentType1')
        assert.are.equal(multiSystem.targets['ComponentType1'][1], entity)

        multiSystem:RemoveEntity(entity)
        assert.is_equal(#multiSystem.targets['ComponentType1'], 0)
    end)

    it(':PickRequiredComponents() returns the requested components', function()
        local addedComponent1 = lovetoys.Class('Component1')()
        entity:Add(addedComponent1)
        requireSystem:AddEntity(entity)

        local returnedComponent1, nonExistentComponent = requireSystem:PickRequiredComponents(entity)
        assert.are.equal(returnedComponent1, addedComponent1)
        assert.is_nil(nonExistentComponent)
    end)

    it(':PickRequiredComponents() throws debug message on multiple requirement systems', function()

        local addedComponent1 = lovetoys.Class('Component1')()
        entity:Add(addedComponent1)
        multiSystem:AddEntity(entity)

        -- Mock lovetoys debug function
        local debug_spy = spy.on(lovetoys, 'debug')

        local returnValue = multiSystem:PickRequiredComponents(entity)
        assert.are.equal(returnValue, nil)

        -- Check for called debug message
        assert.spy(debug_spy).was_called()
        lovetoys.debug:revert()
    end)

    it(':Initialize() shouldnt allow mixed requirements in requires()', function()
         local IllDefinedSystem = lovetoys.Class('IllDefinedSystem', lovetoys.System)
         function IllDefinedSystem:Requires()
             return {'ComponentA', GroupA = {'ComponentB'}}
         end
         assert.has_error(IllDefinedSystem)
    end)

    it(':RemoveEntity calls onRemoveEntity for system with requirement groups', function()
         local Component1 = lovetoys.Class('Component1')
         entity:Add(Component1())

         local cb_spy = spy.on(multiSystem, 'onRemoveEntity')
         multiSystem:AddEntity(entity, 'ComponentType1')
         multiSystem:RemoveEntity(entity)

         assert.spy(cb_spy).was.called_with(multiSystem, entity, 'ComponentType1')
         assert.spy(cb_spy).was.called(1)
    end)

    it(':RemoveEntity calls onRemoveEntity for system with no requirement groups', function()
         local Component1 = lovetoys.Class('Component1')
         entity:Add(Component1())

         local cb_spy = spy.on(requireSystem, 'onRemoveEntity')

         requireSystem:AddEntity(entity)
         requireSystem:RemoveEntity(entity)

         assert.spy(cb_spy).was.called_with(requireSystem, entity)
         assert.spy(cb_spy).was.called(1)
    end)
end)
