pavlov.specify("ServerEvents", function(){
describe("ServerEvents", function(){
  before(function(){
    Entities().node(new Node());
  });
  after(function(){
    ServerEvents().clear()
    if(ServerEvents().handle.restore) ServerEvents().handle.restore();
    if(ServerEvents().raise_event.restore) ServerEvents().raise_event.restore();
    if(Entities().find.restore) Entities().find.restore();
    if(Entities().node().clear_handlers.restore) Entities().node().clear_handlers.restore();
  });

  describe("#handle", function(){
    it("creates callback for the server event", function(){
      ServerEvents().handle('motel::on_movement')
      assert(ServerEvents().callbacks['motel::on_movement']).isTypeOf("function");
    });
    it("clears handlers on node for the server event", function(){
      var spy = sinon.spy(Entities().node(), 'clear_handlers');
      ServerEvents().handle('motel::on_movement')
      sinon.assert.calledWith(spy, 'motel::on_movement')
    })
    it("adds handler to node for the server event", function(){
      ServerEvents().handle('motel::on_movement')
      assert(Entities().node().handlers['motel::on_movement'].length).equals(1)
    })
    it("adds handlers for multiple server events", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      ServerEvents().handle(['motel::on_movement', 'motel::on_rotation'])
      sinon.assert.calledWith(spy, 'motel::on_movement')
      sinon.assert.calledWith(spy, 'motel::on_rotation')
    })

    describe("#on server event", function(){
      var se, cb;
      before(function(){
        se = ServerEvents();
        se.handle('motel::on_movement')
        cb = se.callbacks['motel::on_movement'];
      })

      it("raises the server event on self", function(){
        var spy = sinon.spy(se, 'raise_event')
        cb.apply(se, ["foobar"]);
        sinon.assert.calledWith(spy, 'motel::on_movement', 'foobar')
      })

      it("retreives entity to raise event on from Entities", function(){
        var spy = sinon.spy(Entities(), 'find')
        cb.apply(se, [{id : 42}])
        sinon.assert.called(spy);
        //sinon.assert.calledWith(spy, 'motel::on_movement', with_id(42))
      })

      it("raises server event on entity", function(){
        var entity = new Entity();
        var spy = sinon.spy(entity, 'raise_event');
        var fstub = sinon.stub(Entities(), 'find').returns(entity);
        cb.apply(se, [{id : 42}])
        sinon.assert.calledWith(spy, 'motel::on_movement', {id : 42})
      })
    });
  });

  describe("#clear", function(){
    it("clears handler on node for the server event", function(){
      ServerEvents().handle('motel::on_movement')
      ServerEvents().clear('motel::on_movement')
      assert(Entities().node().handlers['motel::on_movement'].length).equals(0)
    })
    it("removes callback for the specified server event", function(){
      ServerEvents().handle('motel::on_movement')
      ServerEvents().clear('motel::on_movement')
      assert(ServerEvents().callbacks['motel::on_movement']).isNull();
    })
    it("removes callback for all server event", function(){
      ServerEvents().handle('motel::on_movement')
      ServerEvents().clear();
      assert(ServerEvents().callbacks).isSameAs({})
    })
  });

});}); // ServerEvents

pavlov.specify("Events", function(){
describe("Events", function(){
  before(function(){
    Entities().node(new Node());
  });

  after(function(){
    ServerEvents().clear()
    if(ServerEvents().handle.restore) ServerEvents().handle.restore();
    if(Entities().node().ws_request.restore) Entities().node().ws_request.restore();
    if(Entities().node().web_request.restore) Entities().node().web_request.restore();
  })

  describe("#track_movement", function(){
    it("handles motel::location_stopped server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_movement('loc1', 10)
      sinon.assert.calledWith(spy, 'motel::location_stopped')
    })

    it("handles motel::on_movement server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_movement('loc1', 10)
      sinon.assert.calledWith(spy, 'motel::on_movement')
    })

    it("handles motel::on_rotation server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_movement('loc1', 10)
      sinon.assert.calledWith(spy, 'motel::on_rotation')
    })

    it("invokes motel::track_stops", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_movement('loc1', 10)
      sinon.assert.calledWith(spy, 'motel::track_stops', 'loc1')
    })

    it("invokes motel::track_movement", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_movement('loc1', 10)
      sinon.assert.calledWith(spy, 'motel::track_movement', 'loc1', 10)
    })

    describe("rotation distance is set", function(){
      it("invokes motel::track_rotation", function(){
        var spy = sinon.spy(Entities().node(), 'ws_request')
        Events.track_movement('loc1', 10, 0.5)
        sinon.assert.calledWith(spy, 'motel::track_rotation', 'loc1', 0.5)
      })
    });
  });

  describe("#stop_track_movement", function(){
    it("invokes motel::remove_callbacks", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.stop_track_movement('loc1')
      sinon.assert.calledWith(spy, 'motel::remove_callbacks', 'loc1')
    })
  })

  describe("#track_mining", function(){
    it("handles manufactured::event_occurred server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_mining('ship1')
      sinon.assert.calledWith(spy, 'manufactured::event_occurred')
    })

    it("invokes manfufactured::subscribe_to resource_collected", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_mining('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'resource_collected')
    })

    it("invokes manfufactured::subscribe_to mining_stopped", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_mining('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'mining_stopped')
    })
  })

  describe("#track_offense", function(){
    it("handles manufactured::event_occurred server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_offense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::event_occurred')
    })

    it("invokes manufactured::subscribe_to attacked", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_offense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'attacked')
    })

    it("invokes manufactured::subscribe_to attacked_stop", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_offense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'attacked_stop')
    })
  })

  describe("#track_defense", function(){
    it("handles manufactured::event_occurred server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_defense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::event_occurred')
    })

    it("invokes manufactured::subscribe_to defended", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_defense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'defended')
    })

    it("invokes manufactured::subscribe_to defended_stop", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_defense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'defended_stop')
    })

    it("invokes manufactured::subscribe_to destroyed", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_defense('ship1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'ship1', 'destroyed')
    })
  })

  describe("#track_construction", function(){
    it("handles manufactured::event_occurred server event", function(){
      var spy = sinon.spy(ServerEvents(), 'handle')
      Events.track_construction('station1')
      sinon.assert.calledWith(spy, 'manufactured::event_occurred')
    })

    it("invokes manufactured::subscribe_to construction_complete", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_construction('station1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'station1', 'construction_complete')
    })

    it("invokes manufactured::subscribe_to partial_construction", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.track_construction('station1')
      sinon.assert.calledWith(spy, 'manufactured::subscribe_to', 'station1', 'partial_construction')
    })
  })

  describe("#stop_track_manufactured", function(){
    it("invokes manufactured::remove_callbacks", function(){
      var spy = sinon.spy(Entities().node(), 'ws_request')
      Events.stop_track_manufactured('ship1')
      sinon.assert.calledWith(spy, 'manufactured::remove_callbacks', 'ship1');
    });
  })

});}); // Events

pavlov.specify("Commands", function(){
describe("Commands", function(){
  before(function(){
    disable_three_js();
    Entities().node(new Node());
  })

  after(function(){
    reenable_three_js();
    Session.current_session = null;
    if(Entities().select.restore) Entities().select.restore();
    if(Commands.jump_ship.restore) Commands.jump_ship.restore();
  })

  describe("#trigger_jump_gate", function(){
    it("retrieves registry ships owned by user within trigger distance of gate", function(){
      var spy = sinon.spy(Entities(), 'select')
      Session.current_session = { user_id : 'test' }
      Commands.trigger_jump_gate(new JumpGate({location : new Location({x:0,y:0,z:0}),
                                               trigger_distance : 10}))

      sinon.assert.calledWith(spy,
        sinon.match.func_domain(false, {json_class : 'foobar'}).and(
        sinon.match.func_domain(false, {json_class : 'Manufactured::Ship',
                                        user_id    : 'foobar'}).and(
        sinon.match.func_domain(false, {json_class : 'Manufactured::Ship',
                                        user_id    : 'test',
                                        location   : new Location({x:100,y:100,z:100})}).and(
        sinon.match.func_domain(true, {json_class : 'Manufactured::Ship',
                                       user_id    : 'test',
                                       location   : new Location({x:0,y:0,z:0})})))));
    })

    it("invokes Commands.jump_ship w/ each entity", function(){
      var sh1 = new Ship(), sh2 = new Ship();
      var sys = new SolarSystem();
      var stub = sinon.stub(Entities(), 'select').returns([sh1, sh2])
      var spy = sinon.spy(Commands, 'jump_ship')
      Commands.trigger_jump_gate(new JumpGate({endpoint_system : sys}))
      sinon.assert.calledWith(spy, sh1, sys);
      sinon.assert.calledWith(spy, sh2, sys);
    })

    it("raises triggered event on jump gate with each entity", function(){
      var sh1  = new Ship(), sh2 = new Ship();
      var sys  = new SolarSystem();
      var jg   = new JumpGate({endpoint_system : sys});
      var stub = sinon.stub(Entities(), 'select').returns([sh1, sh2])
      var spy  = sinon.spy(jg, 'raise_event');
      Commands.trigger_jump_gate(jg); 
      sinon.assert.calledWith(spy, 'triggered', sh1);
      sinon.assert.calledWith(spy, 'triggered', sh2);
    })

    describe("callback specified", function(){
      it("invokes callback with jump gate and entities", function(){
      var sh1  = new Ship(), sh2 = new Ship();
      var sys  = new SolarSystem();
      var jg   = new JumpGate({endpoint_system : sys});
      var stub = sinon.stub(Entities(), 'select').returns([sh1, sh2])
      var spy  = sinon.spy()
      Commands.trigger_jump_gate(jg, spy); 
      sinon.assert.calledWith(spy, jg, [sh1, sh2]);
      });
    })
  })

  describe("#jump_ship", function(){
    var sh; var sys; var osys;

    before(function(){
      osys = new SolarSystem();
      sh  = new Ship({id : 41, location : new Location(), solar_system : osys});
      sys = new SolarSystem({location : new Location({id : 42})});
    })

    it("sets ship's location parent_id", function(){
      Commands.jump_ship(sh, sys);
      assert(sh.location.parent_id).equals(sys.location.id);
    })

    it("invokes manufactured::move_entity", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.jump_ship(sh, sys);
      sinon.assert.calledWith(spy, 'manufactured::move_entity', sh.id, sh.location);
    })

    describe("successful move_entity result received", function(){
      var cb;
      before(function(){
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.jump_ship(sh, sys);
        cb = spy.getCall(0).args[3];
      })

      it("updates ship solar system", function(){
        cb.apply(null, [{}])
        assert(sh.system_id).equals(sys.id)
        assert(sh.solar_system).equals(sys)
      })

      it("raises jumped event on ship", function(){
        var spy = sinon.spy(sh, 'raise_event')
        cb.apply(null, [{}])
        sinon.assert.calledWith(spy, 'jumped', osys, sys)
      })
    })
  })

  describe("#move_ship", function(){
    var sh;

    before(function(){
      sh = new Ship({location : new Location()});
    })

    it("updates ship's location", function(){
      var l = new Location();
      var stub = sinon.stub(sh.location, 'clone').returns(l)
      Commands.move_ship(sh, 10, 20, -30)
      assert(l.x).equals(10)
      assert(l.y).equals(20)
      assert(l.z).equals(-30)
    })

    it("invokes manufactured::move_entity", function(){
      var l = new Location();
      var stub = sinon.stub(sh.location, 'clone').returns(l)
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.move_ship(sh, 10, 20, -30)
      sinon.assert.calledWith(spy, 'manufactured::move_entity', sh.id, l);
    })

    describe("result callback specified", function(){
      it("invokes callback on move_entity result", function(){
        var l = new Location();
        var stub = sinon.stub(sh.location, 'clone').returns(l)
        var spy = sinon.spy(Entities().node(), 'web_request');
        var cb  = function() {}
        Commands.move_ship(sh, 10, 20, -30, cb)
        assert(spy.getCall(0).args[3]).equals(cb);
      })
    })
  })

  describe("#launch_attack", function(){
    var at; var df;

    before(function(){
      at = new Ship();
      df = new Ship();
    })

    it("invokes manufactured::attack_entity", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.launch_attack(at, df)
      sinon.assert.calledWith(spy, 'manufactured::attack_entity', at.id, df.id);
    })

    describe("result callback specified", function(){
      it("invokes callback on attack_entity result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.launch_attack(at, df, cb)
        assert(spy.getCall(0).args[3]).equals(cb);
      })
    })
  })

  describe("#dock_ship", function(){
    var sh; var st;

    before(function(){
      sh = new Ship();
      st = new Station();
    })

    it("invokes manufactured::dock", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.dock_ship(sh, st)
      sinon.assert.calledWith(spy, 'manufactured::dock', sh.id, st.id);
    })

    describe("result callback specified", function(){
      it("invokes callback on dock result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.dock_ship(sh, st, cb)
        assert(spy.getCall(0).args[3]).equals(cb);
      })
    })
  })

  describe("#undock_ship", function(){
    var sh;

    before(function(){
      sh = new Ship();
    })

    it("invokes manufactured::undock", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.undock_ship(sh)
      sinon.assert.calledWith(spy, 'manufactured::undock', sh.id);
    })

    describe("result callback specified", function(){
      it("invokes callback on undock result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.undock_ship(sh, cb)
        assert(spy.getCall(0).args[2]).equals(cb);
      })
    })
  })

  describe("#transfer_resources", function(){
    var sh; var st;
    var r1; var r2;

    before(function(){
      r1 = {}; r2 = {};
      sh = new Ship({id : 'ship1'});
      sh.resources = [r1, r2]
      st = new Station({id : 'station1'});
    })

    it("invokes manufactured::transfer_resource for each ship resource", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.transfer_resources(sh, st.id)
      sinon.assert.calledWith(spy, 'manufactured::transfer_resource', sh.id, st.id, r1);
      sinon.assert.calledWith(spy, 'manufactured::transfer_resource', sh.id, st.id, r2);
    })

    describe("result callback specified", function(){
      it("invokes callback on each transfer_resource result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.transfer_resources(sh, st.id, cb)
        assert(spy.getCall(0).args[4]).equals(cb);
        assert(spy.getCall(1).args[4]).equals(cb);
      })
    })
  })

  describe("#start_mining", function(){
    var sh; var rs;

    before(function(){
      rs = "ABCDEF"
      sh = new Ship({id : 'ship1'})
    });

    it("invokes manufactured::start_mining", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.start_mining(sh, rs)
      sinon.assert.calledWith(spy, 'manufactured::start_mining', sh.id, rs)
    })

    describe("result callback specified", function(){
      it("invokes callback on start_mining result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.start_mining(sh, rs, cb)
        assert(spy.getCall(0).args[3]).equals(cb);
      })
    })
  })

  describe("#construct_entity", function(){
    var st;

    before(function(){
      st = new Station({id : 'station1'})
    });

    it("invokes manufactured::construct_entity", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.construct_entity(st)
      sinon.assert.calledWith(spy, 'manufactured::construct_entity', st.id,
                                   'Manufactured::Ship')
    })

    describe("result callback specified", function(){
      it("invokes callback on construct_entity result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.construct_entity(st, cb)
        assert(spy.getCall(0).args[3]).equals(cb);
      })
    })
  })

  describe("#assign_mission", function(){
    var mission; var user;

    before(function(){
      mission = 'mission1'
      user = 'user1'
    });

    it("invokes missions::assign_mission", function(){
      var spy = sinon.spy(Entities().node(), 'web_request');
      Commands.assign_mission(mission, user)
      sinon.assert.calledWith(spy, 'missions::assign_mission', mission,
                                   'user1')
    })

    describe("result callback specified", function(){
      it("invokes callback on assign_mission result", function(){
        var cb  = function() {}
        var spy = sinon.spy(Entities().node(), 'web_request');
        Commands.assign_mission(mission, user, cb)
        assert(spy.getCall(0).args[3]).equals(cb);
      })
    })
  })

});}); // Commands
