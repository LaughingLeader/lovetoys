local lovetoys = require('')
lovetoys.Initialize()

describe('Eventmanager', function()
    local Listener, TestEvent
    local listener, eventManager, testEvent

    setup(
    function()
        -- Test Listener
        Listener = lovetoys.Class('Listener')
        Listener.number = 0
        function Listener:test(event)
            self.number = event.number
        end
        -- Test Event
        TestEvent = lovetoys.Class('TestEvent')
        TestEvent.number = 12
    end
    )

    before_each(
    function()
        eventManager = lovetoys.EventManager()
        listener = Listener()
        testEvent = TestEvent()
    end
    )

    it('addListener() adds Listener', function()
        eventManager:AddListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1], listener )
    end)

    it('addListener() doesn`t add Listener twice', function()
        eventManager:AddListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1].number , 0)
        -- Creation of new Listener with same name but different variable
        listener = Listener()
        listener.number = 5
        eventManager:AddListener('TestEvent', listener, listener.test)
        assert.are_not.equal(eventManager.eventListeners['TestEvent'][1][1].number, 5)
    end)

    it('addListener() without function throws debug message', function()
        -- Mock lovetoys debug function
        local debug_spy = spy.on(lovetoys, 'debug')

        eventManager:AddListener('TestEvent', listener, 'lol')

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        lovetoys.debug:revert()
    end)

    it('addListener() without listener.class.name on listener throws debug message', function()
        -- Mock lovetoys debug function
        local debug_spy = spy.on(lovetoys, 'debug')

        eventManager:AddListener('TestEvent', {class={}}, listener.test)

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        eventManager:AddListener('TestEvent', {}, listener.test)
        assert.spy(debug_spy).was_called()
        lovetoys.debug:revert()
    end)

    it('removeListener() removes Listener', function()
        eventManager:AddListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1], listener )

        eventManager:RemoveListener('TestEvent', listener.class.name)
        assert.are.equal(eventManager.eventListeners['TestEvent'][1], nil )
    end)

    it('removeListener() on unregistered listener throws debug message', function()
        -- Mock lovetoys debug function
        local debug_spy = spy.on(lovetoys, 'debug')

        eventManager:RemoveListener('TestEvent', listener)

        -- Assert that the debug function hast been called
        assert.spy(debug_spy).was_called()
        lovetoys.debug:clear()

        eventManager:AddListener('TestEvent', listener, listener.test)
        eventManager:RemoveListener('TestEvent', listener)
        eventManager:RemoveListener('TestEvent', listener)
        assert.spy(debug_spy).was_called()

        lovetoys.debug:revert()
    end)


    it('fireEvent() listener Function is beeing called', function()
        eventManager:AddListener('TestEvent', listener, listener.test)
        assert.are.equal(type(eventManager.eventListeners['TestEvent']), 'table')
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1], listener )

        eventManager:FireEvent(testEvent)
        assert.are.equal(eventManager.eventListeners['TestEvent'][1][1].number , testEvent.number)
    end)

end)
