local lovetoys = require('')
lovetoys.initialize()

describe('Component', function()
    it(':create with defaults creates a Component with default values', function()
        local c = lovetoys.Component.Create('TestComponent',
          {'defaultField', 'emptyField'},
          {defaultField = 'defaultValue'})

        local instance = c()
        assert.are.equal(instance.defaultField, 'defaultValue')
        assert.is_nil(instance.emptyField)
    end)

    it(':load returns the specified components', function()
        local c1 = lovetoys.Component.Create('TestComponent1')
        local c2 = lovetoys.Class('TestComponent2')
        lovetoys.Component.Register(c2)
        local c3 = lovetoys.Class('TestComponent3')

        local loaded1, loaded2, loaded3 = lovetoys.Component.Load({
            'TestComponent1', 'TestComponent2', 'TestComponent3'
        })

        assert.are.equal(loaded1, c1)
        assert.are.equal(loaded2, c2)
        assert.is_nil(loaded3)
    end)
end)
