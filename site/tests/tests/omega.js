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
    it("clears entity container contents");
    it("adds entity details to entity container");
    it("shows entity container");
  });
  describe("#motel_event", function(){
    it("updates entity ownining location");
    describe("scene has entity", function(){
      it("updates entity in scene");
    });
    describe("entity selected", function(){
      it("refreshes entity container");
    });
  });
  describe("#manufactured_event", function(){
    describe("resource_collected", function(){
      it("updates ship");
      describe("scene has ship", function(){
        it("animates scene");
      });
    });
    describe("mining_stopped", function(){
      it("updates ship");
      describe("scene has ship", function(){
        it("animates scene");
      });
    });
    describe("attacked", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = defender");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("attacked_stop", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = null");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("defended", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = defender");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("defended_stop", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = null");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("destroyed", function(){
      it("updates attacker");
      it("updates defender");
      it("sets attacker.attacker = null");
      describe("scene has attacker or defender", function(){
        it("animates scene");
      });
    });
    describe("construction_complete", function(){
      it("retrieves ship with id");
      it("adds ship to registry")
      it("processes entity")
    });
  });
  describe("#process_stats", function(){
    it("adds badges to account info");
  });
  describe("#handle_events", function(){
    it("handles click event");
    describe("entity clicked", function(){
      it("invokes clicked entity callback");
    });
  });
  describe("#clicked_entity", function(){
    describe("clicked solar system", function(){
      it("dispatches to clicked system");
    });
    describe("clicked asteroid", function(){
      it("dispatches to clicked asteroid");
    });
    describe("clicked ship", function(){
      it("dispatches to clicked ship");
    });
    describe("clicked station", function(){
      it("dispatches to clicked station");
    });
  });
  describe("#popup_entity_container", function(){
    it("clears entity container callbacks");
    it("handles hide event");
    describe("container hidden", function(){
      it("unselects selected entity");
      it("hides dialog");
    });
    it("handles entity unselected event");
    it("entity unselected");
    describe("entity container visible", function(){
      it("hides entity container");
    });
    it("clears entity container contents");
    it("adds entity details to entity container");
    it("shows entity container");
  });
  describe("#clicked_system", function(){
    it("sets scene");
  });
  describe("#clicked_asteroid", function(){
    it("invokes cosmos::get_resources");
    describe("on resource retrieval", function(){
      it("appends resource information to entity container");
    });
  });
  describe("#clicked_ship", function(){
    describe("ship does not belong to current user", function(){
      it("just returns");
    });

    it("clears ship callbacks for all commmands");
    it("handles all ship commands");
    describe("on ship 'selection' commands", function(){
      it("it pops up dialog to make selection");
    });
    describe("on ship 'finish selection' commands", function(){
      it("closes dialog");
      it("animates scene");
    });
    describe("on ship 'reload' commands", function(){
      it("reloads entity in scene");
    });
    describe("on ship mining selection command", function(){
      it("retrieves asteroids in the vicinity");
      it("invokes cosmos::get_resources for each asteroid");
      describe("on resources retreived", function(){
        it("adds resource info to dialog");
      });
    });
  });
  describe("#clicked_station", function(){
    describe("station does not belong to current user", function(){
      it("just returns");
    });
  });
  describe("#load_system", function(){
    it("TODO")
  });
  describe("#load_galaxy", function(){
    it("TODO")
  });
  describe("#wire_up_ui", function(){
    it("wires up nav container");
    it("wires up status indicator");
    it("wires up jplayer");
    it("wires up entities lists");
    it("wires up canvas");
    it("wires up chat container");
    it("wires up account info container");
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

  describe("#wire_up_jplayer", function(){
    it("TODO");
  });

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
