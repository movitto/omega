pavlov.specify("omega.js", function(){
  describe("restore_session", function(){
    after(function(){
      if(Session.restore_from_cookie.restore) Session.restore_from_cookie.restore();
      if(login_anon.restore) login_anon.restore();
      if(session_established.restore) session_established.restore();
    });

    it("restores session from cookie", function(){
      var spy = sinon.spy(Session, 'restore_from_cookie');
      restore_session(new UI(), new TestNode());
      sinon.assert.called(spy);
    });

    describe("session is null", function(){
      it("logs in as anon", function(){
        sinon.stub(Session, 'restore_from_cookie').returns(null);
        login_anon = sinon.spy(login_anon);
        restore_session(new UI(), new TestNode());
        sinon.assert.called(login_anon);
      });
    });

    describe("session is not null", function(){
      var session;

      before(function(){
        session = new Session({});
        sinon.stub(Session, 'restore_from_cookie').returns(session);
      })

      it("sets headers on node", function(){
        var spy = sinon.spy(session, 'set_headers_on');
        restore_session(new UI(), new TestNode());
        sinon.assert.called(spy);
      });

      it("validates session", function(){
        var spy = sinon.spy(session, 'validate');
        restore_session(new UI(), new TestNode());
        sinon.assert.called(spy);
      });

      describe("error on session validation", function(){
        it("logs in as anon", function(){
          var stub = sinon.stub(session, 'validate');
          restore_session(new UI(), new TestNode());
          var cb = stub.getCall(0).args[1];

          login_anon = sinon.spy(login_anon);
          cb.apply(null, [{ error : 'invalid session'}])
          sinon.assert.called(login_anon);
        });
      });

      describe("session validated successfully", function(){
        it("establishes session", function(){
          var stub = sinon.stub(session, 'validate');
          restore_session(new UI(), new TestNode());
          var cb = stub.getCall(0).args[1];

          session_established = sinon.spy(session_established);
          cb.apply(null, [{ result : { id : 'user42' } }])
          sinon.assert.called(session_established);
        });
      });

      //it("invokes callback on session validation")
    });
  }); // restore_session

  describe("login_anon", function(){
    after(function(){
      if(Session.login.restore) Session.login.restore();
    })

    it("logs in anon user using session", function(){
      var spy = sinon.spy(Session, 'login');
      var n = new TestNode()
      login_anon(n);
      sinon.assert.calledWith(spy, User.anon_user, n);
    });

    //it("invokes callbacks on login")
  });

  describe("#session_established", function(){
    after(function(){
      if(Entities().node.restore) Entities().node.restore();
      if(Ship.owned_by.restore) Ship.owned_by.restore();
      if(Station.owned_by.restore) Station.owned_by.restore();
      if(Statistic.with_id.restore) Statistic.with_id.restore();
    });

    it("sets global node", function(){
      var spy = sinon.spy(Entities(), 'node');
      var node = new TestNode();
      session_established(new UI(), node, new Session({}), new User());
      sinon.assert.calledWith(spy, node);
    });

    it("shows logout controls", function(){
      var ui  = new UI();
      var spy = sinon.spy(ui.nav_container, 'show_logout_controls');
      session_established(ui, new TestNode(), new Session({}), new User());
      sinon.assert.called(spy);
    });

    it("handles chat notifications", function(){
      var node = new TestNode();
      session_established(new UI(), node, new Session({}), new User());
      assert(obj_keys(node.handlers)).includes('users::on_message')
    });

    it("subscribes to chat messages", function(){
      var node = new TestNode();
      var spy = sinon.spy(node, 'ws_request');
      session_established(new UI(), node, new Session({}), new User());
      sinon.assert.calledWith(spy, 'users::subscribe_to_messages');
    });

    describe("on chat message", function(){
      it("adds message to chat container", function(){
        var ui = new UI();
        var node = new TestNode();
        session_established(ui, node, new Session({}), new User());

        var cb = node.handlers['users::on_message'][0];
        var spy = sinon.spy(ui.chat_container.output, 'append');
        cb.apply(null, [{ nick : 'mmorsi', message : 'hello world' }]);
        sinon.assert.calledWith(spy, "mmorsi: hello world\n")
      });
    });

    it("shows chat container", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.chat_container.toggle_control(), 'show');
      session_established(ui, new TestNode(), new Session({}), new User());
      sinon.assert.called(spy);
    });

    it("shows missions button", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.missions_button, 'show');
      session_established(ui, new TestNode(), new Session({}), new User());
      sinon.assert.called(spy);
    });

    it("retrieves and processes ships owned by user", function(){
      var spy = sinon.spy(Ship, 'owned_by')
      session_established(new UI(), new TestNode(), new Session({}), new User());
      sinon.assert.called(spy);
      // TODO ensure process_entities is called w/ results
    })

    it("retrieves and processes stations owned by user", function(){
      var spy = sinon.spy(Station, 'owned_by')
      session_established(new UI(), new TestNode(), new Session({}), new User());
      sinon.assert.called(spy);
      // TODO ensure process_entities is called w/ results
    })

    // TODO
    //it("populates account information")

    it("retrieves stats", function(){
      var spy = sinon.spy(Statistic, 'with_id')
      session_established(new UI(), new TestNode(), new Session({}), new User());
      sinon.assert.calledWith(spy, 'most_entities', 10, process_stats);
      // TODO ensure process_stats is called w/ results
    });
  });

  describe("#process_entities", function(){
    before(function(){
      disable_three_js();
      Entities().node(new TestNode());
    })

    after(function(){
      reenable_three_js();
      if(process_entity.restore) process_entity.restore();
      if(Entities().set.restore) Entities().set.restore();
      if(handle_events.restore) handle_events.restore();
    })

    it("adds user entities to account info", function(){
      Session.current_session = { user_id : 'user1' };
      var sh1 = new Ship({id : 'ship1', user_id : 'user1'})
      var sh2 = new Ship({id : 'ship2', user_id : 'user2'})
      var ui  = new UI();
      var spy = sinon.spy(ui.account_info, 'entities');
      process_entities(ui, new TestNode(), [sh1, sh2]);
      sinon.assert.calledWith(spy, [sh1])
    });

    it("processes each entity", function(){
      var ui = new UI();
      var node = new TestNode();
      Session.current_session = { user_id : 'user1' };
      var sh1 = new Ship({id : 'ship1', user_id : 'user1'})
      var sh2 = new Ship({id : 'ship2', user_id : 'user1'})
      process_entity = sinon.spy(process_entity);
      process_entities(ui, node, [sh1, sh2]);
      sinon.assert.calledWith(process_entity, ui, node, sh1)
      sinon.assert.calledWith(process_entity, ui, node, sh2)
    });
  });

  describe("#process_entity", function(){
    before(function(){
      disable_three_js();
      Entities().node(new TestNode());
    })

    after(function(){
      if(Entities().set.restore) Entities().set.restore();
      if(Events.track_movement.restore) Events.track_movement.restore();
      if(Events.track_construction.restore) Events.track_construction.restore();
      if(Events.track_mining.restore) Events.track_mining.restore();
      if(Events.track_offense.restore) Events.track_offense.restore();
      if(Events.track_defense.restore) Events.track_defense.restore();
      if(motel_event.restore) motel_event.restore();
      if(manufactured_event.restore) manufactured_event.restore();
      if(load_system.restore) load_system.restore();
    });

    describe("entity in registry", function(){
      it("updates entity", function(){
        var s = new Ship();
        Entities().set('ship1', s)
        var spy = sinon.spy(s, 'update');

        var ns =  new Ship({id : 'ship1'});
        process_entity(new UI(), new TestNode(), ns);
        sinon.assert.calledWith(spy, ns);
      });
    });

    describe("entity not in registry", function(){
      it("adds entity to registry", function(){
        var spy = sinon.spy(Entities(), 'set');
        var s = new Ship({id : 'ship1'})
        process_entity(new UI(), new TestNode(), s);
        sinon.assert.called(spy, 'ship1', s);
      });
    });

    it("stores location in registry", function(){
      var spy = sinon.spy(Entities(), 'set');
      var s = new Ship({id : 'ship1', location : new Location({id : 5})})
      process_entity(new UI(), new TestNode(), s);
      sinon.assert.calledWith(spy, 5, s.location);
    })

    it("adds entity to entities container", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.entities_container, 'add_item');
      var s = new Ship({ id : 'ship1' });
      process_entity(ui, new TestNode(), s)
      sinon.assert.calledWith(spy,
        sinon.match({ text : s.id, id : "entities_container-" + s.id }).and(
        sinon.match(function(v) { return v.item.id == s.id })
        ));
                                     
    })

    it("shows entities container", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.entities_container, 'show');
      process_entity(ui, new TestNode(), new Ship({id : 'ship1'}))
      sinon.assert.called(spy);
    })

    it("handles entity page events", function(){
      handle_events = sinon.spy(handle_events)
      var u = new UI();
      var n = new TestNode();
      var s = new Ship({ id : 'ship1' })
      process_entity(u, n, s)
      sinon.assert.called(handle_events, u, n, s);
    })

    describe("entity jumped", function(){
      it("removes entity from scene", function(){
        var u = new UI();
        var n = new TestNode();
        var s = new Ship({ id : 'ship1' })
        process_entity(u, n, s)
        assert(s.callbacks['jumped'].length).equals(1);

        var spy1 = sinon.spy(u.canvas.scene, 'remove_entity');
        var spy2 = sinon.spy(u.canvas.scene, 'animate');
        s.callbacks['jumped'][0].apply(null, [s]);
        sinon.assert.calledWith(spy1, 'ship1')
        sinon.assert.called(spy2);
      });
    });

    it("track entity movement/rotation/stops", function(){
      var s = new Ship({ id : 'ship1', location : new Location({id : 'l42' }) });
      var spy = sinon.spy(Events, 'track_movement');
      process_entity(new UI(), new TestNode(), s);
      sinon.assert.calledWith(spy, s.location.id);
    });

    describe("entity movement/rotation/stop", function(){
      it("invokes a motel_event", function(){
        var u = new UI();
        var n = new TestNode();
        var s = new Ship({ id : 'ship1', location : new Location({id : 'l42' }) });
        Entities().set(s.id, s);

        process_entity(u, n, s);
        assert(s.location.callbacks['motel::on_movement'].length).equals(1)
        assert(s.location.callbacks['motel::on_rotation'].length).equals(1)
        assert(s.location.callbacks['motel::location_stopped'].length).equals(1)

        var oloc = { id : 'l42' };
        var nloc = { id : 'l42' }
        var loc_match =
          sinon.match(function(e) { return e[0] == oloc && e[1] == nloc; });

        motel_event = sinon.spy(motel_event);
        var cb = s.location.callbacks['motel::on_movement'][0];
        cb.apply(null, [oloc, nloc]);
        sinon.assert.calledWith(motel_event, u, n, loc_match);

        motel_event.reset();
        cb = s.location.callbacks['motel::on_rotation'][0];
        cb.apply(null, [oloc, nloc]);
        sinon.assert.calledWith(motel_event, u, n, loc_match)

        motel_event.reset();
        cb = s.location.callbacks['motel::location_stopped'][0];
        cb.apply(null, [oloc, nloc]);
        sinon.assert.calledWith(motel_event, u, n, loc_match);
      });
    });

    it("tracks manu events", function(){
      var spy1 = sinon.spy(Events, 'track_construction');
      var spy2 = sinon.spy(Events, 'track_mining');
      var spy3 = sinon.spy(Events, 'track_offense');
      var spy4 = sinon.spy(Events, 'track_defense');
      var s = new Ship({ id : 'ship1', location : new Location({id : 'l42' }) });
      process_entity(new UI(), new TestNode(), s);
      sinon.assert.calledWith(spy1, s.id);
      sinon.assert.calledWith(spy2, s.id);
      sinon.assert.calledWith(spy3, s.id);
      sinon.assert.calledWith(spy4, s.id);
    });

    describe("manu event occurred", function(){
      it("invokes a manufactured event", function(){
        var u = new UI();
        var n = new TestNode();
        var s = new Ship({ id : 'ship1', location : new Location({id : 'l42' }) });
        Entities().set(s.id, s);

        process_entity(u, n, s);
        assert(s.callbacks['manufactured::event_occurred'].length).equals(1)

        manufactured_event = sinon.spy(manufactured_event);
        var cb = s.callbacks['manufactured::event_occurred'][0];
        cb.apply(null, ['test']);
        sinon.assert.calledWith(manufactured_event, u, n,
          sinon.match(function(e){ return e[0] == 'test'; }));
      });
    });

    it("loads system entity is in", function(){
      var u = new UI();
      var n = new TestNode();
      var s = new Ship({ id : 'ship1',
                         system_id : 'sys1',
                         location : new Location({id : 'l42' }) });
      load_system = sinon.spy(load_system);
      process_entity(u, n, s);
      sinon.assert.calledWith(load_system, 'sys1', u, n);
    });

    describe("system loaded", function(){
      it("sets entity solar system", function(){
        var u = new UI();
        var n = new TestNode();
        var s = new Ship({ id : 'ship1',
                           system_id : 'sys1',
                           location : new Location({id : 'l42' }) });
        load_system = sinon.spy(load_system);
        process_entity(u, n, s);

        var sys = new SolarSystem();
        var cb = load_system.getCall(0).args[3];
        cb.apply(null, [sys]);
        assert(s.solar_system).equals(sys);
      });
    });
  });

  describe("#refresh_entity_container", function(){
    var ui; var entity;
    before(function(){
      entity = { details : function() { return 'test'; }}
      ui = new UI();
    })

    it("clears entity container contents", function(){
      var spy = sinon.spy(ui.entity_container.contents, 'clear')
      refresh_entity_container(ui, null, entity);
      sinon.assert.called(spy)
    });

    it("adds entity details to entity container", function(){
      var spy = sinon.spy(ui.entity_container.contents, 'add_text')
      refresh_entity_container(ui, null, entity);
      sinon.assert.calledWith(spy, 'test')
    });

    it("shows entity container", function(){
      var spy = sinon.spy(ui.entity_container, 'show')
      refresh_entity_container(ui, null, entity);
      sinon.assert.called(spy)
    });
  });

  describe("#motel_event", function(){
    var ui, node, entity, oloc, nloc;

    before(function(){
      disable_three_js();
      Entities().node(new TestNode());

      ui = new UI();
      node = new TestNode();
      entity = new Ship({ id : 'ship1', location : new Location({id : 'l42' }) });
      Entities().set(entity.id, entity);

      oloc = { id : 'l42' };
      nloc = { id : 'l42' }

      Session.current_session = {};
    })

    after(function(){
      if(refresh_entity_container.restore) refresh_entity_container.restore();
    })

    it("updates entity owning location", function(){
      var spy = sinon.spy(entity, 'update');
      motel_event(ui, node, [oloc, nloc]);
      sinon.assert.calledWith(spy, { location : nloc});
    });

    describe("scene has entity", function(){
      it("updates entity in scene", function(){
        ui.canvas.scene.add_entity(entity);
        var spy = sinon.spy(ui.canvas.scene, 'animate');
        motel_event(ui, node, [oloc, nloc]);
        sinon.assert.called(spy);
      });
    });
    describe("entity selected", function(){
      it("refreshes entity container", function(){
        entity.selected = true;
        refresh_entity_container = sinon.spy(refresh_entity_container);
        motel_event(ui, node, [oloc, nloc]);
        sinon.assert.calledWith(refresh_entity_container, ui, node, entity);
      });
    });
  });

  describe("#manufactured_event", function(){
    var ui, node;
    var miner, corvette;
    var constructor, constructed;

    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);

      miner = new Ship({ id : 'ship1', location : new Location({id : 'l42' }) });
      corvette = new Ship({ id : 'ship2', location : new Location({id : 'l43' }) });
      Entities().set(miner.id, miner);
      Entities().set(corvette.id, corvette);

      constructor = new Station({ id : 'station1'})
      constructed = new Ship({ id : 'ship3' })
      Entities().set(constructor.id, constructor);
    })

    describe("resource_collected", function(){
      it("updates ship", function(){
        var spy = sinon.spy(miner, 'update')
        var nminer = { id : miner.id };
        manufactured_event(ui, node,
          [null, 'resource_collected', nminer, {}, 50])
        sinon.assert.calledWith(spy, nminer)
      });

      describe("scene has ship", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          manufactured_event(ui, node,
            [null, 'resource_collected', nminer, {}, 50])
          sinon.assert.called(spy);
        });
      });
    });

    describe("mining_stopped", function(){
      it("updates ship", function(){
        var spy = sinon.spy(miner, 'update')
        var nminer = { id : miner.id };
        manufactured_event(ui, node,
          [null, 'mining_stopped', 'cargo_full', nminer])
        sinon.assert.calledWith(spy, nminer)
        assert(miner.mining).isNull();
      });

      describe("scene has ship", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          manufactured_event(ui, node,
            [null, 'mining_stopped', 'cargo_full', nminer])
          sinon.assert.called(spy);
        });
      });
    });

    describe("attacked", function(){
      it("updates attacker/defender", function(){
        var spy1 = sinon.spy(miner, 'update')
        var spy2 = sinon.spy(corvette, 'update')
        var nminer = { id : miner.id };
        var ncorvette = { id : corvette.id };
        manufactured_event(ui, node,
          [null, 'attacked', ncorvette, nminer])
        sinon.assert.calledWith(spy1, nminer)
        sinon.assert.calledWith(spy2, ncorvette)
        assert(corvette.attacking).equals(miner);
      });

      describe("scene has attacker or defender", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          var ncorvette = { id : corvette.id };
          manufactured_event(ui, node,
            [null, 'attacked', ncorvette, nminer])
          sinon.assert.called(spy);

          spy.reset();
          ui.canvas.scene.remove_entity(miner);
          ui.canvas.scene.add_entity(corvette)
          manufactured_event(ui, node,
            [null, 'attacked', ncorvette, nminer])
          sinon.assert.called(spy);
        });
      });
    });

    describe("attacked_stop", function(){
      it("updates attacker/defender", function(){
        var spy1 = sinon.spy(miner, 'update')
        var spy2 = sinon.spy(corvette, 'update')
        var nminer = { id : miner.id };
        var ncorvette = { id : corvette.id };
        manufactured_event(ui, node,
          [null, 'attacked_stop', ncorvette, nminer])
        sinon.assert.calledWith(spy1, nminer)
        sinon.assert.calledWith(spy2, ncorvette)
        assert(corvette.attacking).isNull();
      });

      describe("scene has attacker or defender", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          var ncorvette = { id : corvette.id };
          manufactured_event(ui, node,
            [null, 'attacked_stop', ncorvette, nminer])
          sinon.assert.called(spy);

          spy.reset();
          ui.canvas.scene.remove_entity(miner);
          ui.canvas.scene.add_entity(corvette)
          manufactured_event(ui, node,
            [null, 'attacked_stop', ncorvette, nminer])
          sinon.assert.called(spy);
        });
      });
    });

    describe("defended", function(){
      it("updates attacker/defender", function(){
        var spy1 = sinon.spy(miner, 'update')
        var spy2 = sinon.spy(corvette, 'update')
        var nminer = { id : miner.id };
        var ncorvette = { id : corvette.id };
        manufactured_event(ui, node,
          [null, 'defended', ncorvette, nminer])
        sinon.assert.calledWith(spy1, nminer)
        sinon.assert.calledWith(spy2, ncorvette)
        assert(corvette.attacking).equals(miner);
      });

      describe("scene has attacker or defender", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          var ncorvette = { id : corvette.id };
          manufactured_event(ui, node,
            [null, 'defended', ncorvette, nminer])
          sinon.assert.called(spy);

          spy.reset();
          ui.canvas.scene.remove_entity(miner);
          ui.canvas.scene.add_entity(corvette)
          manufactured_event(ui, node,
            [null, 'defended', ncorvette, nminer])
          sinon.assert.called(spy);
        });
      });
    });

    describe("defended_stop", function(){
      it("updates attacker/defender", function(){
        var spy1 = sinon.spy(miner, 'update')
        var spy2 = sinon.spy(corvette, 'update')
        var nminer = { id : miner.id };
        var ncorvette = { id : corvette.id };
        manufactured_event(ui, node,
          [null, 'defended_stop', ncorvette, nminer])
        sinon.assert.calledWith(spy1, nminer)
        sinon.assert.calledWith(spy2, ncorvette)
        assert(corvette.attacking).isNull();
      });

      describe("scene has attacker or defender", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          var ncorvette = { id : corvette.id };
          manufactured_event(ui, node,
            [null, 'defended_stop', ncorvette, nminer])
          sinon.assert.called(spy);

          spy.reset();
          ui.canvas.scene.remove_entity(miner);
          ui.canvas.scene.add_entity(corvette)
          manufactured_event(ui, node,
            [null, 'defended_stop', ncorvette, nminer])
          sinon.assert.called(spy);
        });
      });
    });

    describe("destroyed", function(){
      it("updates attacker/defender", function(){
        var spy1 = sinon.spy(miner, 'update')
        var spy2 = sinon.spy(corvette, 'update')
        var nminer = { id : miner.id };
        var ncorvette = { id : corvette.id };
        manufactured_event(ui, node,
          [null, 'destroyed', ncorvette, nminer])
        sinon.assert.calledWith(spy1, nminer)
        sinon.assert.calledWith(spy2, ncorvette)
        assert(corvette.attacking).isNull();
      });

      describe("scene has attacker or defender", function(){
        it("animates scene", function(){
          var spy = sinon.spy(ui.canvas.scene, 'animate')
          ui.canvas.scene.add_entity(miner)
          var nminer = { id : miner.id };
          var ncorvette = { id : corvette.id };
          manufactured_event(ui, node,
            [null, 'destroyed', ncorvette, nminer])
          sinon.assert.called(spy);

          spy.reset();
          ui.canvas.scene.remove_entity(miner);
          ui.canvas.scene.add_entity(corvette)
          manufactured_event(ui, node,
            [null, 'destroyed', ncorvette, nminer])
          sinon.assert.called(spy);
        });
      });
    });

    describe("construction_complete", function(){
      after(function(){
        if(Ship.with_id.restore) Ship.with_id.restore();
        if(process_entity.restore) process_entity.restore();
      })

      it("retrieves ship with id", function(){
        var spy = sinon.spy(Ship, 'with_id')
        nconstructor = { id : constructor.id }
        nconstructed = { id : constructed.id }
        manufactured_event(ui, node,
          [null, 'construction_complete', nconstructor, nconstructed])
        sinon.assert.calledWith(spy, nconstructed.id)
      });

      describe("on entity retrieval", function(){
        it("adds ship to registry and processes", function(){
          var spy = sinon.spy(Ship, 'with_id')
          nconstructor = { id : constructor.id }
          nconstructed = { id : constructed.id }
          manufactured_event(ui, node,
            [null, 'construction_complete', nconstructor, nconstructed])
          var cb = spy.getCall(0).args[1];

          process_entity = sinon.spy(process_entity);
          cb.apply(null, [nconstructed]);
          assert(Entities().get(nconstructed.id)).isNotNull();
          sinon.assert.calledWith(process_entity, ui, node, nconstructed);
        })
      });
    });
  });

  //describe("#process_stats", function(){ // NIY
  //  it("adds badges to account info");
  //});

  describe("#handle_events", function(){
    var ui, node;
    var e1, e2;

    before(function(){
      ui = new UI();
      node = new TestNode();

      e1 = new Entity({ id : 'e1', details : function() { return ""; }});
      e2 = new Entity({ id : 'e2', details : function() { return ""; }});
    })

    after(function(){
      if(handle_events.restore) handle_events.restore();
      if(clicked_entity.restore) clicked_entity.restore();
    })

    it("handles multiple entities", function(){
      handle_events = sinon.spy(handle_events);
      handle_events(ui, node, [e1, e2]);
      sinon.assert.calledWith(handle_events, ui, node, e1);
      sinon.assert.calledWith(handle_events, ui, node, e2);
    });

    it("handles click event", function(){
      handle_events(ui, node, e1);
      assert(e1.callbacks['click'].length).equals(1)
    });

    describe("entity clicked", function(){
      it("invokes clicked entity callback", function(){
        handle_events(ui, node, e1);
        cb = e1.callbacks['click'][0];

        clicked_entity = sinon.spy(clicked_entity);
        cb.apply(null, [e1])
        sinon.assert.calledWith(clicked_entity, ui, node, e1)
      });
    });
  });

  describe("#clicked_entity", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);

      if(popup_entity_container.restore) popup_entity_container.restore();
      if(clicked_system.restore) clicked_system.restore();
      if(clicked_asteroid.restore) clicked_asteroid.restore();
      if(clicked_ship.restore) clicked_ship.restore();
      if(clicked_station.restore) clicked_station.restore();
    })

    it("unselects currently selected entity", function(){
      var s1 = new Ship({ id : 42 });
      var s2 = new Ship({ id : 43 });
      s1.selected = true
      Entities().set(s1.id, s1)
      ui.canvas.scene.add_entity(s1);

      clicked_entity(ui, node, s2);
      assert(s1.selected).isFalse();
    });

    describe("clicked solar system", function(){
      it("dispatches to clicked system", function(){
        var sys = new SolarSystem();
        clicked_system = sinon.spy(clicked_system);
        clicked_entity(ui, node, sys);
        sinon.assert.calledWith(clicked_system, ui, node, sys);
      });
    });

    describe("clicked asteroid", function(){
      it("pops up entity container", function(){
        var asteroid = new Asteroid();
        popup_entity_container = sinon.spy(popup_entity_container);
        clicked_entity(ui, node, asteroid);
        sinon.assert.calledWith(popup_entity_container, ui, node, asteroid);
      });

      it("dispatches to clicked asteroid", function(){
        var asteroid = new Asteroid();
        clicked_asteroid = sinon.spy(clicked_asteroid);
        clicked_entity(ui, node, asteroid);
        sinon.assert.calledWith(clicked_asteroid, ui, node, asteroid);
      });
    });

    describe("clicked ship", function(){
      it("pops up entity container", function(){
        var ship = new Ship();
        popup_entity_container = sinon.spy(popup_entity_container);
        clicked_entity(ui, node, ship);
        sinon.assert.calledWith(popup_entity_container, ui, node, ship);
      });

      it("dispatches to clicked ship", function(){
        var ship = new Ship();
        clicked_ship = sinon.spy(clicked_ship);
        clicked_entity(ui, node, ship);
        sinon.assert.calledWith(clicked_ship, ui, node, ship);
      });
    });

    describe("clicked station", function(){
      it("pops up entity container", function(){
        var station = new Station();
        popup_entity_container = sinon.spy(popup_entity_container);
        clicked_entity(ui, node, station);
        sinon.assert.calledWith(popup_entity_container, ui, node, station);
      });

      it("dispatches to clicked station", function(){
        var station = new Station();
        clicked_station = sinon.spy(clicked_station);
        clicked_entity(ui, node, station);
        sinon.assert.calledWith(clicked_station, ui, node, station);
      });
    });
  });

  describe("#popup_entity_container", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);
    })

    it("clears entity container callbacks", function(){
      var spy = sinon.spy(ui.entity_container, 'clear_callbacks')
      popup_entity_container(ui, node, new Ship());
      sinon.assert.called(spy);
    });

    it("handles hide event", function(){
      popup_entity_container(ui, node, new Ship());
      assert(ui.entity_container.callbacks['hide'].length).equals(1)
    });

    describe("container hidden", function(){
      var cb;
      before(function(){
        popup_entity_container(ui, node, new Ship({ id : 'ship1' }));
        cb = ui.entity_container.callbacks['hide'][0];
      })

      it("unselects selected entity", function(){
        var spy = sinon.spy(ui.canvas.scene, 'unselect');
        cb.apply(null, []);
        sinon.assert.calledWith(spy, 'ship1');
      });

      it("hides dialog", function(){
        var spy = sinon.spy(ui.dialog, 'hide');
        cb.apply(null, []);
        sinon.assert.called(spy);
      });
    });

    it("handles entity unselected event", function(){
      var s = new Ship();
      popup_entity_container(ui, node, s);
      assert(s.callbacks['unselected'].length).equals(1)
    });

    describe("entity unselected", function(){
      it("hides entity container", function(){
        var s = new Ship();
        popup_entity_container(ui, node, s);

        ui.entity_container.show();
        var spy = sinon.spy(ui.entity_container, 'hide');

        var cb = s.callbacks['unselected'][0];
        cb.apply(null, []);
        sinon.assert.called(spy);
      });
    });

    it("clears entity container contents", function(){
      var spy = sinon.spy(ui.entity_container.contents, 'clear');
      var s = new Ship();
      popup_entity_container(ui, node, s);
      sinon.assert.called(spy);
    });

    it("adds entity details to entity container", function(){
      var spy = sinon.spy(ui.entity_container.contents, 'add_text');
      var s = new Ship();
      s.details = function() { return "text"; }
      popup_entity_container(ui, node, s);
      sinon.assert.calledWith(spy, 'text');
    });

    it("shows entity container", function(){
      var spy = sinon.spy(ui.entity_container, 'show');
      var s = new Ship();
      popup_entity_container(ui, node, s);
      sinon.assert.called(spy);
    });
  });

  describe("#clicked_system", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);

      if(set_scene.restore) set_scene.restore();
    })

    it("sets scene", function(){
      set_scene = sinon.spy(set_scene);
      var sys = new SolarSystem()
      clicked_system(ui, node, sys);
      sinon.assert.calledWith(set_scene, ui, sys);
    });
  });

  describe("#clicked_asteroid", function(){
    var ui, node;

    before(function(){
      ui   = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);
    })

    it("invokes cosmos::get_resources", function(){
      var spy = sinon.spy(node, 'web_request');
      var ast = new Asteroid({ id : 'ast1' });
      clicked_asteroid(ui, node, ast);
      sinon.assert.calledWith(spy, 'cosmos::get_resources', ast.id);
    });

    describe("on resource retrieval", function(){
      it("appends resource information to entity container", function(){
        var spy1 = sinon.spy(node, 'web_request');
        var ast = new Asteroid({ id : 'ast1' });
        clicked_asteroid(ui, node, ast);

        var spy2 = sinon.spy(ui.entity_container.contents, 'add_item');

        var cb = spy1.getCall(0).args[2];
        var res = { result : [{id : 'res1', quantity: 50, material_id: 'metal-steel'}]};
        cb.apply(null, [res]);

        sinon.assert.calledWith(spy2,
          [{id: 'resources_title', text: 'Resources: <br/>'},
           {id : 'res1', text: '50 of metal-steel<br/>'}])
      });
    });
  });

  describe("#clicked_ship", function(){
    var ui, node;
    var ship;
    var cmds =
      ['cmd_move_select', 'cmd_attack_select',
       'cmd_dock_select', 'cmd_mine_select',
       'cmd_move', 'cmd_attack',
       'cmd_dock', 'cmd_mine',
       'cmd_dock', 'cmd_undock'];

    before(function(){
      ui   = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);

      Session.current_session = { user_id : 'user1' }
      ship = new Ship({ user_id : 'user1',
                        location : new Location({x:0,y:0,z:0}) });
    })

    it("clears ship callbacks for all commmands", function(){
      var spy = sinon.spy(ship, 'clear_callbacks');
      clicked_ship(ui, node, ship);
      for( var c in cmds)
        sinon.assert.calledWith(spy, cmds[c]);
    });

    it("handles all ship commands", function(){
      clicked_ship(ui, node, ship);
      for(var c in cmds)
        assert(ship.callbacks[cmds[c]]).notEmpty();
    });

    describe("on ship 'selection' commands", function(){
      it("it pops up dialog to make selection", function(){
        clicked_ship(ui, node, ship);
        var cb = ship.callbacks['cmd_move_select'][0]; // TODO teset other selection cmds?
        cb.apply(null, ['cmd_move_select', ship, 'title', 'content']);
        assert(ui.dialog.visible()).isTrue();
        assert(ui.dialog.title).equals('title')
        assert(ui.dialog.text).equals('content')
      });
    });

    describe("on ship 'finish selection' commands", function(){
      it("closes dialog/animates scene", function(){
        clicked_ship(ui, node, ship);
        var cb = ship.callbacks['cmd_move'][0]; // TODO teset other finished selection cmds?
        var spy1 = sinon.spy(ui.canvas.scene, 'animate')
        var spy2 = sinon.spy(ui.dialog, 'hide')
        cb.apply(null, ['cmd_move', ship]);
        sinon.assert.called(spy1)
        sinon.assert.called(spy2)
      });
    });

    describe("on ship 'reload' commands", function(){
      it("reloads entity in scene", function(){
        clicked_ship(ui, node, ship);
        var cb = ship.callbacks['cmd_undock'][0]; // TODO teset other reload cmds?
        var spy = sinon.spy(ui.canvas.scene, 'reload_entity')
        cb.apply(null, ['cmd_undock', ship]);
        sinon.assert.calledWith(spy, ship)
      });
    });

    describe("on ship mining selection command", function(){
      after(function(){
        if(Entities().select.restore) Entities().select.restore();
      })

      it("retrieves asteroids in the vicinity", function(){
        clicked_ship(ui, node, ship);
        var cb = ship.callbacks['cmd_mine_select'][1];

        var spy = sinon.spy(Entities(), 'select')
        cb.apply(null, ['cmd_mine_select', ship]);
        sinon.assert.calledWith(spy,
          sinon.match.func_domain(false, {json_class : 'foobar'}).and(
          sinon.match.func_domain(false, {json_class : 'Cosmos::Asteroid',
                                          location : new Location({x:100,y:100,z:100})})).and(
          sinon.match.func_domain(true,  {json_class : 'Cosmos::Asteroid',
                                          location : new Location({x:0,y:0,z:0})})))
      });

      it("invokes cosmos::get_resources for each asteroid", function(){
        clicked_ship(ui, node, ship);
        var cb = ship.callbacks['cmd_mine_select'][1];
        var stub =
          sinon.stub(Entities(), 'select').returns([new Asteroid({id:'ast1'})]);

        var spy = sinon.spy(node, 'web_request')
        cb.apply(null, ['cmd_mine_select', ship]);
        sinon.assert.calledWith(spy, 'cosmos::get_resources', 'ast1')
      });

      describe("on resources retreived", function(){
        it("adds resource info to dialog", function(){
          clicked_ship(ui, node, ship);
          var cb = ship.callbacks['cmd_mine_select'][1];
          var stub =
            sinon.stub(Entities(), 'select').returns([new Asteroid({id:'ast1'})]);

          var spy = sinon.spy(node, 'web_request')
          cb.apply(null, ['cmd_mine_select', ship]);

          var cb2 = spy.getCall(0).args[2];
          var res = {result : [{ id : 'res1', material_id : 'gem-diamond', quantity : 100}]}

          var spy2 = sinon.spy(ui.dialog, 'append');
          cb.apply(null, [res]);
          sinon.assert.called(spy); // TODO with content generated from res
        });
      });
    });
  });

  //describe("#clicked_station", function(){ // NIY
  //});
  //describe("#load_system", function(){ // NIY
  //});
  //describe("#load_galaxy", function(){ // NIY
  //});

  describe("#wire_up_ui", function(){
    var ui, node;
    before(function(){
      ui = new UI();
      node = new TestNode();
    })

    after(function(){
      if(wire_up_nav.restore) wire_up_nav.restore();
      if(wire_up_status.restore) wire_up_status.restore();
      if(wire_up_jplayer.restore) wire_up_jplayer.restore();
      if(wire_up_entities_lists.restore) wire_up_entities_lists.restore();
      if(wire_up_canvas.restore) wire_up_canvas.restore();
      if(wire_up_chat.restore) wire_up_chat.restore();
      if(wire_up_account_info.restore) wire_up_account_info.restore();
    })

    it("wires up all ui subsystems", function(){
      wire_up_nav = sinon.spy(wire_up_nav);
      wire_up_status = sinon.spy(wire_up_status);
      wire_up_jplayer = sinon.spy(wire_up_jplayer);
      wire_up_entities_lists = sinon.spy(wire_up_entities_lists);
      wire_up_canvas = sinon.spy(wire_up_canvas);
      wire_up_chat = sinon.spy(wire_up_chat);
      wire_up_account_info = sinon.spy(wire_up_account_info);

      wire_up_ui(ui, node);
      sinon.assert.calledWith(wire_up_nav, ui, node);
      sinon.assert.calledWith(wire_up_status, ui, node);
      sinon.assert.calledWith(wire_up_jplayer, ui, node);
      sinon.assert.calledWith(wire_up_entities_lists, ui, node);
      sinon.assert.calledWith(wire_up_canvas, ui, node);
      sinon.assert.calledWith(wire_up_chat, ui, node);
      sinon.assert.calledWith(wire_up_account_info, ui, node);
    });
  });

  describe("#wire_up_nav", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();
    })

    after(function(){
      if(Session.login.restore) Session.login.restore();
    });

    it("handles login link click event", function(){
      wire_up_nav(ui, node);
      assert(ui.nav_container.login_link.callbacks['click'].length).equals(1);
    });

    describe("on login link click", function(){
      it("pops up login dialog", function(){
        wire_up_nav(ui, node);
        var cb = ui.nav_container.login_link.callbacks['click'][0];
        cb.apply(null, []);
        assert(ui.dialog.visible());
        assert(ui.dialog.title).equals('Login')
        assert(ui.dialog.text).equals('')
        assert(ui.dialog.selector).equals('#login_dialog')
      });
    });

    it("handles login button click event", function(){
      wire_up_nav(ui, node);
      assert(ui.nav_container.login_button.callbacks['click'].length).equals(1);
    });

    describe("on login button click", function(){
      var cb;

      before(function(){
        wire_up_nav(ui, node);
        cb = ui.nav_container.login_button.callbacks['click'][0];

        // click login link to popup login dialog
        ui.nav_container.login_link.callbacks['click'][0].apply(null, [])
      })

      after(function(){
        if(session_established.restore) session_established.restore();
      })

      it("hides login dialog", function(){
        var spy = sinon.spy(ui.dialog, 'hide')
        cb.apply(null, []);
        sinon.assert.called(spy);
      });

      it("logs dialog user in", function(){
        ui.dialog.subdiv('#login_username').attr('value', 'uid');
        ui.dialog.subdiv('#login_password').attr('value', 'ups');

        var spy = sinon.spy(Session, 'login')
        cb.apply(null, []);
        sinon.assert.calledWith(spy, sinon.match(function(v){
          return v.id == 'uid' && v.password == 'ups';
        }), node);
      });

      describe("on successful user login", function(){
        it("establishes session", function(){
          var spy = sinon.spy(Session, 'login')
          cb.apply(null, []);

          var cb2 = spy.getCall(0).args[2];
          session_established = sinon.spy(session_established);
          cb2.apply(null, [new Session({})])
          sinon.assert.called(session_established);
        });
      });
    });

    it("handles register link click event", function(){
      wire_up_nav(ui, node);
      assert(ui.nav_container.register_link.callbacks['click'].length).equals(1);
    });

    describe("on register link click", function(){
      it("pops up register dialog", function(){
        wire_up_nav(ui, node);
        var cb = ui.nav_container.register_link.callbacks['click'][0];
        cb.apply(null, []);
        assert(ui.dialog.visible());
        assert(ui.dialog.title).equals('Register')
        assert(ui.dialog.text).equals('')
        assert(ui.dialog.selector).equals('#register_dialog')
      });

      //it("generates recpatcha"); // NIY
    });

    it("handles register button click event", function(){
      wire_up_nav(ui, node);
      assert(ui.nav_container.register_button.callbacks['click'].length).equals(1);
    });

    describe("on register button click", function(){
      var cb;

      before(function(){
        wire_up_nav(ui, node);
        cb = ui.nav_container.register_button.callbacks['click'][0];

        // click register link to popup register dialog
        ui.nav_container.register_link.callbacks['click'][0].apply(null, [])
      })

      it("hides register dialog", function(){
        var spy = sinon.spy(ui.dialog, 'hide')
        cb.apply(null, []);
        sinon.assert.called(spy);
      });

      it("invokes register dialog user web request", function(){
        ui.dialog.subdiv('#register_username').attr('value', 'uid');
        ui.dialog.subdiv('#register_password').attr('value', 'ups');
        ui.dialog.subdiv('#register_email').attr('value', 'uem');

        var spy = sinon.spy(node, 'web_request');
        cb.apply(null, []);
        sinon.assert.calledWith(spy, 'users::register', sinon.match(function(v){
          // TODO also validate recaptcha / recaptcha response
          return v.id == 'uid' && v.password == 'ups' && v.email == 'uem';
        }));
      });

      describe("on failed user registration", function(){
        it("shows failed registration dialog with reason", function(){
          var spy = sinon.spy(node, 'web_request');
          cb.apply(null, []);

          var cb2 = spy.getCall(0).args[2];
          cb2.apply(null, [{ error : { message : 'invalid email'}}])
          assert(ui.dialog.visible()).isTrue();
          assert(ui.dialog.title).equals('Failed to create account');
          assert(ui.dialog.selector).equals('#registration_failed_dialog');
          assert(ui.dialog.text).equals('invalid email');
        });
      });

      describe("on successful user registration", function(){
        it("shows successful registration dialog", function(){
          var spy = sinon.spy(node, 'web_request');
          cb.apply(null, []);

          var cb2 = spy.getCall(0).args[2];
          cb2.apply(null, [{}])
          assert(ui.dialog.visible()).isTrue();
          assert(ui.dialog.title).equals('Creating Account');
          assert(ui.dialog.selector).equals('#registration_submitted_dialog');
          assert(ui.dialog.text).equals('');
        });
      });
    });

    it("handles logout link click event", function(){
      wire_up_nav(ui, node);
      assert(ui.nav_container.logout_link.callbacks['click'].length).equals(1);
    });

    describe("on logout link click", function(){
      var cb;

      before(function(){
        wire_up_nav(ui, node);
        cb = ui.nav_container.logout_link.callbacks['click'][0];
        Session.current_session = new Session({});
      })

      after(function(){
        if(Session.logout.restore) Session.logout.restore();
        Session.current_session = null;
      })

      it("logs the session out", function(){
        var spy = sinon.spy(Session, 'logout');
        cb.apply(null, []);
        sinon.assert.calledWith(spy, node);
        // TODO assert login_anon is invoked upon response
      });

      it("hides ui components", function(){
        var spies = [sinon.spy(ui.missions_button, 'hide'),
                     sinon.spy(ui.entities_container, 'hide'),
                     sinon.spy(ui.locations_container, 'hide'),
                     sinon.spy(ui.entity_container, 'hide'),
                     sinon.spy(ui.dialog, 'hide'),
                     sinon.spy(ui.chat_container, 'hide'),
                     sinon.spy(ui.chat_container.toggle_control(), 'hide')];
        cb.apply(null, []);
        for(var spy in spies)
          sinon.assert.called(spies[spy]);
      });

      it("clears canvas scene / resets canvas camera", function(){
        var spy1 = sinon.spy(ui.canvas.scene, 'clear_entities');
        var spy2 = sinon.spy(ui.canvas.scene.camera, 'reset');
        cb.apply(null, []);
        sinon.assert.called(spy1);
        sinon.assert.called(spy2);
      });

      it("hides canvas skybox/axis/grid", function(){
        var spy1 = sinon.spy(ui.canvas.scene.skybox, 'shide');
        var spy2 = sinon.spy(ui.canvas.scene.axis, 'shide');
        var spy3 = sinon.spy(ui.canvas.scene.grid, 'shide');
        cb.apply(null, []);
        sinon.assert.called(spy1);
        sinon.assert.called(spy2);
        sinon.assert.called(spy3);
      });

      it("shows login controls", function(){
        var spy = sinon.spy(ui.nav_container, 'show_login_controls');
        cb.apply(null, []);
        sinon.assert.called(spy);
      });
    });
  });

  describe("#wire_up_status", function(){
    var ui, node;
    before(function(){
      ui = new UI();
      node = new TestNode();
    })

    it("handles all node requests", function(){
      wire_up_status(ui, node);
      assert(node.callbacks['request'].length).equals(1);
    });

    describe("on node request", function(){
      it("pushes 'loading' status onto indicator", function(){
        var spy = sinon.spy(ui.status_indicator, 'push_state')
        wire_up_status(ui, node);
        var cb = node.callbacks['request'][0];
        cb.apply(null, []);
        sinon.assert.calledWith(spy, 'loading')
      });
    });

    it("handles all node messages received", function(){
      wire_up_status(ui, node);
      assert(node.callbacks['msg_received'].length).equals(1);
    });

    describe("on node msg received", function(){
      it("pops top status off indicator stack", function(){
        var spy = sinon.spy(ui.status_indicator, 'pop_state')
        wire_up_status(ui, node);
        var cb = node.callbacks['msg_received'][0];
        cb.apply(null, []);
        sinon.assert.called(spy);
      });
    });
  });

  //describe("#wire_up_jplayer", function(){ // NIY ?
  //});

  describe("#wire_up_entities_lists", function(){
    var ui, node;
    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);
    })

    after(function(){
      if(set_scene.restore) set_scene.restore();
      if(show_missions.restore) show_missions.restore();
      if(Mission.all.restore) Mission.all.restore();
      if(Entities().set.restore) Entities().set.restore();
    })

    it("handles locations container click_item events", function(){
      wire_up_entities_lists(ui, node);
      assert(ui.locations_container.callbacks['click_item'].length).equals(1);
    });

    describe("on locations container click_item", function(){
      it("sets scene to clicked item", function(){
        wire_up_entities_lists(ui, node);
        var cb = ui.locations_container.callbacks['click_item'][0];
        set_scene = sinon.spy(set_scene);
        var sys = new SolarSystem();
        cb.apply(null, [null, {item : sys}, null]);
        sinon.assert.calledWith(set_scene, ui, sys);
      });
    });

    it("handles entities container click_item events", function(){
      wire_up_entities_lists(ui, node);
      assert(ui.entities_container.callbacks['click_item'].length).equals(1);
    });

    describe("on entities container click_item", function(){
      it("sets scene to clicked item's solar system", function(){
        wire_up_entities_lists(ui, node);
        var cb = ui.entities_container.callbacks['click_item'][0];
        set_scene = sinon.spy(set_scene);
        var sys = new SolarSystem();
        var loc = new Location();
        cb.apply(null, [null, {item : {solar_system : sys, location : loc}}, null]);
        sinon.assert.calledWith(set_scene, ui, sys, loc);
      });
    });

    it("handles missions button click events", function(){
      wire_up_entities_lists(ui, node);
      assert(ui.missions_button.callbacks['click'].length).equals(1);
    });

    describe("on mission button click", function(){
      it("retrieves/shows all missions", function(){
        var m1 = new Mission({ id : 'm1' });

        wire_up_entities_lists(ui, node);
        var cb = ui.missions_button.callbacks['click'][0];
        var spy = sinon.spy(Mission, 'all')
        cb.apply(null, []);
        sinon.assert.called(spy);

        cb = spy.getCall(0).args[0];
        show_missions = sinon.spy(show_missions);
        spy = sinon.spy(Entities(), 'set');
        cb.apply(null, [[m1]]);
        sinon.assert.calledWith(spy, m1.id, m1);
        sinon.assert.calledWith(show_missions, [m1], ui);
      });
    });

    //describe("on assign mission click", function(){
    //  describe("error during mission assignment", function(){
    //    it("shows error in dialog", function(){ // NIY
    //    });
    //  });

    //  describe("successful mission assignment", function(){
    //    it("updates registry entity") // NIY
    //    it("hides dialog"); // NIY
    //  });
    //});
  });

  describe("#set_scene", function(){
    var ui, sys, node;
    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);

      sys =
        new SolarSystem({ background : 'background',
                          planets    : [new Planet(), new Planet()]});
    })

    after(function(){
      if(Events.track_movement.restore) Events.track_movement.restore();
      if(motel_event.restore) motel_event.restore();
    })

    it("hides dialog", function(){
      var spy = sinon.spy(ui.dialog, 'hide')
      set_scene(ui, sys)
      sinon.assert.called(spy);
    });

    it("unselects selected entity", function(){
      var s1 = new Ship({ id : 42 });
      var s2 = new Ship({ id : 43 });
      s1.selected = true
      Entities().set(s1.id, s1)
      ui.canvas.scene.add_entity(s1);

      set_scene(ui, sys);
      assert(s1.selected).isFalse();
    });

    it("sets skybox background", function(){
      var spy = sinon.spy(ui.canvas.scene.skybox, 'background');
      set_scene(ui, sys)
      sinon.assert.calledWith(spy, sys.background)
    });

    it("removes / readds skybox skybox", function(){
      var spy1 = sinon.spy(ui.canvas.scene, 'remove_component')
      var spy2 = sinon.spy(ui.canvas.scene, 'add_component')
      set_scene(ui, sys);           // TODO need to enable three to test these:
      sinon.assert.calledWith(spy1);//, ui.canvas.scene.skybox.components[0])
      sinon.assert.calledWith(spy2);//, ui.canvas.scene.skybox.components[0])
    });

    it("clears scene entities", function(){
      var spy = sinon.spy(ui.canvas.scene, 'clear_entities')
      set_scene(ui, sys);
      sinon.assert.called(spy);
    });

    it("sets scene root entity", function(){
      var spy = sinon.spy(ui.canvas.scene, 'set')
      set_scene(ui, sys);
      sinon.assert.calledWith(spy, sys);
    });

    describe("camera focus specified", function(){
      it("focuses camera on specified location", function(){
        var loc = new Location();
        var spy = sinon.spy(ui.canvas.scene.camera, 'focus')
        set_scene(ui, sys, loc);
        sinon.assert.calledWith(spy, loc);
      });
    });

    describe("root entity is a solar system", function(){
      it("clears child planet callbacks", function(){
        var spies = [];
        for(var p in sys.planets)
          spies.push(sinon.spy(sys.planets[p], 'clear_callbacks'))
        set_scene(ui, sys);
        for(var s in spies){
          sinon.assert.calledWith(spies[s], 'motel::on_movement')
          sinon.assert.calledWith(spies[s], 'motel::on_rotation')
          sinon.assert.calledWith(spies[s], 'motel::location_stopped')
        }
      });

      it("tracks child planet movement", function(){
        var spy = sinon.spy(Events, 'track_movement')
        set_scene(ui, sys);
        for(var p in sys.planets)
          sinon.assert.calledWith(spy, sys.planets[p].location.id);
      });

      //describe("on planet movement event", function(){ // NIY
      //  it("raises motel event");
      //});
    });
  });

  describe("#show_missions", function(){
    var ui, missions;

    before(function(){
      ui = new UI();
      missions = [new Mission(), new Mission()]
    })

    after(function(){
      Session.current_session = null;
    })

    describe("mission currently in process", function(){
      it("shows current mission details in dialog", function(){
        Session.current_session = { user_id : 'user1'};
        missions.push(new Mission({assigned_to_id : 'user1', assigned_time: new Date().toString() }))

        show_missions(missions, ui);
        assert(ui.dialog.title).equals('Assigned Mission')
        //assert(ui.dialog.text).equals('TODO')
      });
    });

    describe("mission not currently in process", function(){
      it("shows unassigned mission information in dialog", function(){
        show_missions(missions, ui);
        assert(ui.dialog.title).equals('Missions')
        //assert(ui.dialog.text).equals('TODO')
      });

      it("shows victorious/fails mission stats in dialog", function(){
        show_missions(missions, ui);
        assert(ui.dialog.title).equals('Missions')
        //assert(ui.dialog.text).equals('TODO')
      });
    });

    it("shows dialog", function(){
      show_missions(missions, ui);
      assert(ui.dialog.selector).isNull();
      assert(ui.dialog.visible()).isTrue();
    });
  });

  describe("#wire_up_canvas", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();

      disable_three_js();
      Entities().node(node);
    });

    it("dispatches to canvas.wire_up", function(){
      var spy = sinon.spy(ui.canvas, 'wire_up')
      wire_up_canvas(ui, node);
      sinon.assert.called(spy)
    });

    it("dispatches to canvas.scene.camera.wire_up", function(){
      var spy = sinon.spy(ui.canvas.scene.camera, 'wire_up')
      wire_up_canvas(ui, node);
      sinon.assert.called(spy)
    });

    it("dispatches to canvas.scene.axis.cwire_up", function(){
      var spy = sinon.spy(ui.canvas.scene.axis, 'cwire_up')
      wire_up_canvas(ui, node);
      sinon.assert.called(spy)
    });

    it("dispatches to canvas.scene.grid.cwire_up", function(){
      var spy = sinon.spy(ui.canvas.scene.grid, 'cwire_up')
      wire_up_canvas(ui, node);
      sinon.assert.called(spy)
    });

    it("dispatches to entity container.wire_up", function(){
      var spy = sinon.spy(ui.entity_container, 'wire_up')
      wire_up_canvas(ui, node);
      sinon.assert.called(spy)
    });

    describe("on root window resize", function(){
      it("sets canvas size", function(){
        wire_up_canvas(ui, node);

        var spy = sinon.spy(ui.canvas, 'set_size');
        $(window).trigger('resize');
        sinon.assert.called(spy); // TODO test size?
      });
    });

    it("it listens for all texture loading events", function(){
      wire_up_canvas(ui, node);
      assert(UIResources().callbacks['texture_loaded'].length).equals(1)
    });

    describe("on texture loading", function(){
      it("animates scene", function(){
        wire_up_canvas(ui, node);
        var cb = UIResources().callbacks['texture_loaded'][0];
        var spy = sinon.spy(ui.canvas.scene, 'animate')
        cb.apply(null, []);
        sinon.assert.called(spy);
      });
    });

    it("it handles scene set event", function(){
      wire_up_canvas(ui, node);
      assert(ui.canvas.scene.callbacks['set'].length).equals(1)
    });

    describe("on scene set", function(){
      var cb, sys;
      var sh1, sh2;

      before(function(){
        wire_up_canvas(ui, node);
        cb = ui.canvas.scene.callbacks['set'][0];
        
        sys = new SolarSystem({id : 'sys1', location : new Location()})
        Session.current_session = { user_id : 'user1' }
        sh1 = new Ship({ id : 'sh1', user_id : 'user2', system_id : 'sys2', location : new Location({id : 5}) });
        sh2 = new Ship({ id : 'sh2', system_id : 'sys1' , location : new Location()});

        Entities().set(sh1.id, sh1);
        Entities().set(sh2.id, sh2);
      })

      after(function(){
        Session.current_session = null;
        if(Entities().select.restore) Entities().select.restore();
        if(Events.stop_track_movement.restore) Events.stop_track_movement.restore();
        if(Events.stop_track_manufactured.restore) Events.stop_track_manufactured.restore();
        if(SolarSystem.entities_under.restore) SolarSystem.entities_under.restore();
        if(process_entities.restore) process_entities.restore();
      })

      it("removes movement/manu event tracking from all entities not in current system", function(){
        var spy1 = sinon.spy(Entities(), 'select');
        var spy2 = sinon.spy(Events, 'stop_track_movement')
        var spy3 = sinon.spy(Events, 'stop_track_manufactured')

        cb.apply(null, [sys]);
        sinon.assert.calledWith(spy1,
          sinon.match.func_domain(false, { json_class : 'foobar'}).and(
          sinon.match.func_domain(false, { json_class : 'Manufactured::Ship', system_id : sys.id })).and(
          sinon.match.func_domain(false, { json_class : 'Manufactured::Ship', system_id : 'sys2', user_id : 'user1' })).and(
          sinon.match.func_domain(true,  { json_class : 'Manufactured::Ship', system_id : 'sys2', user_id : 'user2' })))
        sinon.assert.calledWith(spy2, sh1.location.id);
        sinon.assert.calledWith(spy3, sh1.id);
      });

      it("refreshes entities under current system", function(){
        var spy = sinon.spy(SolarSystem, 'entities_under');
        cb.apply(null, [sys]);
        sinon.assert.calledWith(spy, sys.id);
        process_entities = sinon.spy(process_entities);
        var cb1 = spy.getCall(0).args[1];
        cb1.apply(null, [[]]);
        sinon.assert.calledWith(process_entities, ui, node, []);
      });

      it("resets the camera", function(){
        var spy = sinon.spy(ui.canvas.scene.camera, 'reset');
        cb.apply(null, [sys]);
        sinon.assert.called(spy);
      });
    });
  });

  describe("#wire_up_chat", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();
    })

    it("dispatches to chat_container.wire_up", function(){
      var spy = sinon.spy(ui.chat_container, 'wire_up')
      wire_up_chat(ui, node);
      sinon.assert.called(spy)
    });

    it("handles chat button click event", function(){
      wire_up_chat(ui, node);
      assert(ui.chat_container.button.callbacks['click'].length).equals(1);
    });

    describe("on chat button click", function(){
      var cb;

      before(function(){
        wire_up_chat(ui, node);
        cb = ui.chat_container.button.callbacks['click'][0];
        ui.chat_container.input.component().attr('value', 'msg'); 
        Session.current_session = { user_id : 'user1' }
      })

      after(function(){
        Session.current_session = null;
      })

      it("sends chat message to server", function(){
        var spy = sinon.spy(node, 'web_request')
        cb.apply(null, []);
        sinon.assert.calledWith(spy, 'users::send_message', 'msg');
      });

      it("adds message to output", function(){
        cb.apply(null, []);
        assert(ui.chat_container.output.component().html()).equals("user1: msg\n")
      });

      it("clears chat input", function(){
        cb.apply(null, []);
        assert(ui.chat_container.input.component().attr('value')).equals('');
      });
    });
  });

  describe("#wire_up_account_info", function(){
    var ui, node;

    before(function(){
      ui = new UI();
      node = new TestNode();
    })

    it("handles account info update button click event", function(){
      wire_up_account_info(ui, node);
      assert(ui.account_info.update_button.callbacks['click'].length).equals(1);
    });

    describe("on account info button click", function(){
      var cb;

      before(function(){
        wire_up_account_info(ui, node);
        cb = ui.account_info.update_button.callbacks['click'][0];
      })

      after(function(){
        if(window.alert.restore) window.alert.restore();
      })

      describe("passwords do no match", function(){
        it("pops up an alert / does not continue", function(){
          // stub out window.alert
          window.alert = sinon.stub(window, 'alert');

          var stub = sinon.stub(ui.account_info, 'passwords_match').returns(false);
          cb.apply(null, []);
          sinon.assert.called(stub);
        });
      });

      it("invokes update_user request", function(){
        var stub = sinon.stub(ui.account_info, 'passwords_match').returns(true);
        var spy1 = sinon.spy(ui.account_info, 'user');
        var spy2 = sinon.spy(node, 'web_request');
        cb.apply(null, []);
        sinon.assert.called(spy1);
        sinon.assert.calledWith(spy2, 'users::update_user')
      });

      //describe("successful user update", function(){ // NIY
      //  it("pops up an alert w/ confirmation");
      //});
    })
  });

}); // omega.js
