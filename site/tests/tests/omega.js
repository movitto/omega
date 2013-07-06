pavlov.specify("omega.js", function(){
  describe("restore_session", function(){
    after(function(){
      if(Session.restore_from_cookie.restore) Session.restore_from_cookie.restore();
      if(login_anon.restore) login_anon.restore();
      if(session_established.restore) session_established.restore();
    });

    it("restores session from cookie", function(){
      var spy = sinon.spy(Session, 'restore_from_cookie');
      restore_session(new UI(), new Node());
      sinon.assert.called(spy);
    });

    describe("session is null", function(){
      it("logs in as anon", function(){
        sinon.stub(Session, 'restore_from_cookie').returns(null);
        login_anon = sinon.spy(login_anon);
        restore_session(new UI(), new Node());
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
        restore_session(new UI(), new Node());
        sinon.assert.called(spy);
      });

      it("validates session", function(){
        var spy = sinon.spy(session, 'validate');
        restore_session(new UI(), new Node());
        sinon.assert.called(spy);
      });

      describe("error on session validation", function(){
        it("logs in as anon", function(){
          var stub = sinon.stub(session, 'validate');
          restore_session(new UI(), new Node());
          var cb = stub.getCall(0).args[1];

          login_anon = sinon.spy(login_anon);
          cb.apply(null, [{ error : 'invalid session'}])
          sinon.assert.called(login_anon);
        });
      });

      describe("session validated successfully", function(){
        it("establishes session", function(){
          var stub = sinon.stub(session, 'validate');
          restore_session(new UI(), new Node());
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
      var n = new Node()
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
      var node = new Node();
      session_established(new UI(), node, new Session({}), new User());
      sinon.assert.calledWith(spy, node);
    });

    it("shows logout controls", function(){
      var ui  = new UI();
      var spy = sinon.spy(ui.nav_container, 'show_logout_controls');
      session_established(ui, new Node(), new Session({}), new User());
      sinon.assert.called(spy);
    });

    it("handles chat notifications", function(){
      var node = new Node();
      session_established(new UI(), node, new Session({}), new User());
      assert(obj_keys(node.handlers)).includes('users::on_message')
    });

    it("subscribes to chat messages", function(){
      var node = new Node();
      var spy = sinon.spy(node, 'ws_request');
      session_established(new UI(), node, new Session({}), new User());
      sinon.assert.calledWith(spy, 'users::subscribe_to_messages');
    });

    describe("on chat message", function(){
      it("adds message to chat container", function(){
        var ui = new UI();
        var node = new Node();
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
      session_established(ui, new Node(), new Session({}), new User());
      sinon.assert.called(spy);
    });

    it("shows missions button", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.missions_button, 'show');
      session_established(ui, new Node(), new Session({}), new User());
      sinon.assert.called(spy);
    });

    it("retrieves and processes ships owned by user", function(){
      var spy = sinon.spy(Ship, 'owned_by')
      session_established(new UI(), new Node(), new Session({}), new User());
      sinon.assert.called(spy);
      // TODO ensure process_entities is called w/ results
    })

    it("retrieves and processes stations owned by user", function(){
      var spy = sinon.spy(Station, 'owned_by')
      session_established(new UI(), new Node(), new Session({}), new User());
      sinon.assert.called(spy);
      // TODO ensure process_entities is called w/ results
    })

    // TODO
    //it("populates account information")

    it("retrieves stats", function(){
      var spy = sinon.spy(Statistic, 'with_id')
      session_established(new UI(), new Node(), new Session({}), new User());
      sinon.assert.calledWith(spy, 'most_entities', 10, process_stats);
      // TODO ensure process_stats is called w/ results
    });
  });

  describe("#process_entities", function(){
    before(function(){
      disable_three_js();
      Entities().node(new Node());
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
      process_entities(ui, new Node(), [sh1, sh2]);
      sinon.assert.calledWith(spy, [sh1])
    });

    it("processes each entity", function(){
      var ui = new UI();
      var node = new Node();
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
      Entities().node(new Node());
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
        process_entity(new UI(), new Node(), ns);
        sinon.assert.calledWith(spy, ns);
      });
    });

    describe("entity not in registry", function(){
      it("adds entity to registry", function(){
        var spy = sinon.spy(Entities(), 'set');
        var s = new Ship({id : 'ship1'})
        process_entity(new UI(), new Node(), s);
        sinon.assert.called(spy, 'ship1', s);
      });
    });

    it("stores location in registry", function(){
      var spy = sinon.spy(Entities(), 'set');
      var s = new Ship({id : 'ship1', location : new Location({id : 5})})
      process_entity(new UI(), new Node(), s);
      sinon.assert.calledWith(spy, 5, s.location);
    })

    it("adds entity to entities container", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.entities_container, 'add_item');
      var s = new Ship({ id : 'ship1' });
      process_entity(ui, new Node(), s)
      sinon.assert.calledWith(spy,
        sinon.match({ text : s.id, id : "entities_container-" + s.id }).and(
        sinon.match(function(v) { return v.item.id == s.id })
        ));
                                     
    })

    it("shows entities container", function(){
      var ui = new UI();
      var spy = sinon.spy(ui.entities_container, 'show');
      process_entity(ui, new Node(), new Ship({id : 'ship1'}))
      sinon.assert.called(spy);
    })

    it("handles entity page events", function(){
      handle_events = sinon.spy(handle_events)
      var u = new UI();
      var n = new Node();
      var s = new Ship({ id : 'ship1' })
      process_entity(u, node, s)
      sinon.assert.called(handle_events, u, n, s);
    })

    describe("entity jumped", function(){
      it("removes entity from scene", function(){
        var u = new UI();
        var n = new Node();
        var s = new Ship({ id : 'ship1' })
        process_entity(u, node, s)
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
      process_entity(new UI(), new Node(), s);
      sinon.assert.calledWith(spy, s.location.id);
    });

    describe("entity movement/rotation/stop", function(){
      it("invokes a motel_event", function(){
        var u = new UI();
        var n = new Node();
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
      process_entity(new UI(), new Node(), s);
      sinon.assert.calledWith(spy1, s.id);
      sinon.assert.calledWith(spy2, s.id);
      sinon.assert.calledWith(spy3, s.id);
      sinon.assert.calledWith(spy4, s.id);
    });

    describe("manu event occurred", function(){
      it("invokes a manufactured event", function(){
        var u = new UI();
        var n = new Node();
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
      var n = new Node();
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
        var n = new Node();
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
      Entities().node(new Node());

      ui = new UI();
      node = new Node();
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
      node = new Node();

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

  // TODO
  //describe("#process_stats", function(){
  //  it("adds badges to account info");
  //});

  describe("#handle_events", function(){
    var ui, node;
    var e1, e2;

    before(function(){
      ui = new UI();
      node = new Node();

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
      node = new Node();

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
      node = new Node();

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
      node = new Node();

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
      node = new Node();

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
      node = new Node();

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
        remove_dialogs();
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

  // TODO
  //describe("#clicked_station", function(){
  //});
  //describe("#load_system", function(){
  //});
  //describe("#load_galaxy", function(){
  //});

  describe("#wire_up_ui", function(){
    var ui, node;
    before(function(){
      ui = new UI();
      node = new Node();
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
    it("handles login link click event");
    describe("on login link click", function(){
      it("pops up login dialog");
    });

    it("handles login button click event");
    describe("on login button click", function(){
      it("hides login dialog");
      it("reads username / password inputs");
      it("creates new user");
      it("logs user in");
      describe("on successful user login", function(){
        it("establishes session");
      });
    });

    it("handles register link click event");
    describe("on register link click", function(){
      it("pops up register dialog");
      it("generates recpatcha");
    });

    it("handles register button click event");
    describe("on register button click", function(){
      it("hides register dialog");
      it("reads username / password / email / recaptcha inputs");
      it("creates new user");
      it("invokes register user web request");
      describe("on failed user registration", function(){
        it("shows failed registration dialog with reason");
      });
      describe("on successful user registration", function(){
        it("shows successful registration dialog");
      });
    });

    it("handles logout link click event");
    describe("on logout link click", function(){
      it("logs the session out");
      it("hides missions button");
      it("hides entities container");
      it("hides locations container");
      it("hides entity container");
      it("hides dialog");
      it("hides chat container");
      it("hides chat container toggle");
      it("clears canvas scene");
      it("hides canvas skybox/axis/grid");
      it("resets canvas camera");
      it("shows login controls");
    });
  });

  describe("#wire_up_status", function(){
    it("handles all node requests");
    describe("on node request", function(){
      it("pushes 'loading' status onto indicator");
    });

    it("handles all node messages received");
    describe("on node msg received", function(){
      it("pops top status off indicator stack");
    });
  });

  // TODO?
  //describe("#wire_up_jplayer", function(){
  //});

  describe("#wire_up_entities_lists", function(){
    it("handles locations container click_item events");
    describe("on locations container click_item", function(){
      it("sets scene to clicked item");
    });
    it("handles entities container click_item events");
    describe("on entities container click_item", function(){
      it("sets scene to clicked item's solar system");
    });
    it("handles missions button click events");
    describe("on mission button click", function(){
      it("retrieves all missions");
      it("shows missions");
    });
    it("handles assign mission click event");
    describe("on assign mission click", function(){
      describe("error during mission assignment", function(){
        it("shows error in dialog");
      });
      describe("successful mission assignment", function(){
        it("updates registry entity")
        it("hides dialog");
      });
    });
  });

  describe("#set_scene", function(){
    it("hides dialog");
    it("unselects selected entity");
    it("removes old skybox");
    it("clears scene entities");
    it("sets scene root entity");
    describe("camera focus specified", function(){
      it("focuses camera on specified location");
    });
    it("sets skybox background");
    it("adds skybox to scene");
    describe("root entity is a solar system", function(){
      it("clears child planet callbacks");
      it("tracks child planet movement");
      describe("on planet movement event", function(){
        it("raises motel event");
      });
    });
  });
  describe("#show_missions", function(){
    it("retrieves unassigned/assigned/victorious/failed/current missions");
    describe("mission currently in process", function(){
      it("shows mission details in dialog");
    });
    describe("mission not currently in process", function(){
      it("shows unassigned mission information in dialog");
      it("shows victorious/fails mission stats in dialog");
    });
    it("shows dialog");
  });
  describe("#wire_up_canvas", function(){
    it("dispatches to canvas.wire_up");
    it("dispatches to canvas.scene.camera.wire_up");
    it("dispatches to canvas.scene.axis.wire_up");
    it("dispatches to canvas.scene.grid.wire_up");
    it("dispatches to entity container.wire_up");
    it("handles window resize events");
    describe("on window resize", function(){
      it("only responds to root windows resize events");
      it("sets canvas size");
    });
    it("it listens for all texture loading events");
    describe("on texture loading", function(){
      it("reanimates scene");
    });
    it("it listens for scene set event");
    describe("on scene set", function(){
      it("removes movement/manu event tracking from all entities not in current system");
      it("refreshes entities under current system");
      it("resets the camera");
    });
  });
  describe("#wire_up_chat", function(){
    it("dispatches to chat_container.wire_up");
    it("handles chat button click event");
    describe("on chat button click", function(){
      it("retrieves chat input");
      it("sends new chat message to server");
      it("adds message to output");
      it("clears chat input");
    });
  });
  describe("#wire_up_account_info", function(){
    it("handles account info update button click event");
    describe("passwords do no match", function(){
      it("pops up an alert / does not continue");
    });
    it("invokes update_user request");
    describe("successful user update", function(){
      it("pops up an alert w/ confirmation");
    });
  });

}); // omega.js
