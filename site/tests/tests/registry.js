pavlov.specify("EventTracker", function(){
describe("EventTracker", function(){
  var tracker;

  before(function(){
    tracker = new EventTracker();
  });

  describe("#on", function(){
    it("registers handler for event", function(){
      var h = function() {};
      tracker.on('test', h)
      assert(tracker.callbacks['test'][0]).equals(h)
    });

    it("registers handler for multiple events", function(){
      var h = function() {};
      tracker.on(['test1', 'test2'], h);
      assert(tracker.callbacks['test1'][0]).equals(h);
      assert(tracker.callbacks['test2'][0]).equals(h);
    });
  });

  describe("#clear_callbacks", function(){
    before(function(){
      var h1 = function() {};
      var h2 = function() {};
      tracker.on('event1', h1)
      tracker.on('event1', h2)
      tracker.on('event2', h1)
    })

    it("clears callbacks for for the specified event", function(){
      tracker.clear_callbacks('event1');
      assert(tracker.callbacks['event1'].length).equals(0)
      assert(tracker.callbacks['event2'].length).equals(1)
    });

    it("clears callbacks for for multiple events", function(){
      tracker.clear_callbacks(['event1', 'event2']);
      assert(tracker.callbacks['event1'].length).equals(0)
      assert(tracker.callbacks['event2'].length).equals(0)
    });

    it("clears callbacks for for all events", function(){
      tracker.clear_callbacks();
      assert(obj_values(tracker.callbacks).length).equals(0);
    });
  });

  describe("#raise_event", function(){
    it("invokes event callbacks", function(){
      var h1 = sinon.spy();
      var h2 = sinon.spy();
      tracker.on('event1', h1)
      tracker.on('event2', h2)
      tracker.raise_event('event1')
      sinon.assert.called(h1)
      sinon.assert.notCalled(h2)
    })
  });

});}); // EventTracker

pavlov.specify("Registry", function(){
describe("Registry", function(){
  var registry;

  before(function(){
    registry = new Registry();
  });

  describe("#get/set", function(){
    it("gets/sets registry entity", function(){
      registry.set('test', 'value');
      assert(registry.get('test')).equals('value');
    });
  });

  describe("#cached", function(){
    describe("registry has entity", function(){
      it("returns entity", function(){
        registry.set('test', 'value');
        assert(registry.cached('test')).equals('value');
      });
    });

    describe("registry does not have entity", function(){
      it("invokes callback", function(){
        var spy = sinon.spy();
        registry.cached('test', spy)
        sinon.assert.called(spy);
      });

      it("sets entity to callback return value", function(){
        var stub = sinon.stub().returns(42);
        assert(registry.cached('test', stub)).equals(42);
        assert(registry.get('test')).equals(42);
      });
    });
  })

  describe("#select", function(){
    it("returns registry entities matching criteria", function(){
      registry.set('a', 10);
      registry.set('b', 11);
      var v = registry.select(function(i) { return i % 2 == 0; });
      assert(v.length).equals(1)
      assert(v[0]).equals(10);
    });
  });

});}); // Registry
