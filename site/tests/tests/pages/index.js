pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  it("loads config", function(){
    var index = new Omega.Pages.Index();
    assert(index.config).equals(Omega.Config);
  });

  it("has a node", function(){
    var index = new Omega.Pages.Index();
    assert(index.node).isOfType(Omega.Node);
  });

  it("has an entities registry", function(){
    var index = new Omega.Pages.Index();
    assert(index.entities).isSameAs({});
  });

  it("has a command tracker", function(){
    var index = new Omega.Pages.Index();
    assert(index.command_tracker).isOfType(Omega.UI.CommandTracker);
  });

  describe("#validate_session", function(){
    var index, session_valid, session_invalid;

    before(function(){
      index = new Omega.Pages.Index();

      session_valid = sinon.stub(index, '_session_validated');
      session_invalid = sinon.stub(index, '_session_invalid');
    });

    after(function(){
      if(Omega.Session.restore_from_cookie.restore) Omega.Session.restore_from_cookie.restore();
    });

    it("restores session from cookie", function(){
      var restore = sinon.spy(Omega.Session, 'restore_from_cookie');
      index.validate_session();
      sinon.assert.called(restore);
    });

    describe("session is not null", function(){
      it("validates session", function(){
        var session = new Omega.Session();
        var spy = sinon.spy(session, 'validate');
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
        index.validate_session();
        sinon.assert.calledWith(spy, index.node);
      });

      describe("session is not valid", function(){
        var session, validate_cb;

        before(function(){
          session = new Omega.Session();
          var spy = sinon.spy(session, 'validate');
          var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

          index.validate_session();
          validate_cb = spy.getCall(0).args[1];
        })

        it("invokes session_invalid", function(){
          validate_cb.apply(null, [{error : {}}]);
          sinon.assert.called(session_invalid);
        });
      });

      describe("user session is valid", function(){
        var session, validate_cb, session_validated;

        before(function(){
          session = new Omega.Session({user_id: 'user1'});
          var spy = sinon.spy(session, 'validate');
          sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

          index.validate_session();
          validate_cb = spy.getCall(0).args[1];
        })

        after(function(){
          Omega.Session.restore_from_cookie.restore();
        })

        it("invokes session_validated", function(){
          validate_cb.apply(null, [{}]);
          sinon.assert.called(session_valid);
        })
      });
    });

    describe("#session is null", function(){
      it("invokes session_invalid", function(){
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(null);
        index.validate_session();
        sinon.assert.called(session_invalid);
      });
    });
  });

  describe("#_session_validated", function(){
    var index, load_universe, load_user_entities;
    before(function(){
      index = new Omega.Pages.Index();

      /// stub out call to load_universe and load_user_entities
      load_universe = sinon.stub(Omega.UI.Loader, 'load_universe');
      load_user_entities = sinon.stub(index, '_load_user_entities');
    });

    after(function(){
      Omega.UI.Loader.load_universe.restore();
    });

    it("shows logout controls", function(){
      spy = sinon.spy(index.nav, 'show_logout_controls');
      index._session_validated();
      sinon.assert.called(spy);
    });

    it("handles events", function(){
      var handle_events = sinon.spy(index, 'handle_events');
      index._session_validated();
      sinon.assert.called(handle_events);
    });

    it("loads universe id", function(){
      index._session_validated();
      sinon.assert.calledWith(load_universe, index, sinon.match.func);
    });

    it("loads user entities", function(){
      index._session_validated();
      var load_cb = load_universe.getCall(0).args[1];
      load_cb();
      sinon.assert.called(load_user_entities);
    });
  });

  describe("#_load_user_entities", function(){
    var index;
    before(function(){
      index = new Omega.Pages.Index();
      index.session = new Omega.Session();
    });

    after(function(){
      if(Omega.Ship.owned_by.restore) Omega.Ship.owned_by.restore();
      if(Omega.Station.owned_by.restore) Omega.Station.owned_by.restore();
    });

    it("retrieves ships owned by user", function(){
      var spy = sinon.spy(Omega.Ship, 'owned_by');
      index._load_user_entities();
      sinon.assert.calledWith(spy, index.session.user_id, index.node, sinon.match.func);
    });

    it("retrieves stations owned by user", function(){
      var spy = sinon.spy(Omega.Station, 'owned_by');
      index._load_user_entities();
      sinon.assert.calledWith(spy, index.session.user_id, index.node, sinon.match.func);
    });

    it("processes entities retrieved", function(){
      var shspy = sinon.spy(Omega.Ship, 'owned_by');
      var stspy = sinon.spy(Omega.Station, 'owned_by');
      index._load_user_entities();

      var shcb = shspy.getCall(0).args[2];
      var stcb = stspy.getCall(0).args[2];

      var spy = sinon.stub(index, 'process_entities');
      shcb('ships')
      stcb('stations');
      sinon.assert.calledWith(spy, 'ships');
      sinon.assert.calledWith(spy, 'stations');
    });
  })

  describe("#_session_invalid", function(){
    var session, index, load_universe;
    before(function(){
      index = new Omega.Pages.Index();
      session = new Omega.Session();
      index.session = session;

      /// stub out load universe call
      load_universe = sinon.stub(Omega.UI.Loader, 'load_universe');
    });

    after(function(){
      Omega.UI.Loader.load_universe.restore();
      if(Omega.Session.login.restore) Omega.Session.login.restore();
    });

    it("clears session cookies", function(){
      var clear_cookies = sinon.spy(session, 'clear_cookies');
      index._session_invalid();
      sinon.assert.called(clear_cookies);
    });

    it("nullifies session", function(){
      index._session_invalid();
      assert(index.session).isNull();
    });

    it("shows login controls", function(){
      var show_login = sinon.spy(index.nav, 'show_login_controls');
      index._session_invalid();
      sinon.assert.called(show_login);
    });

    it("logs anon user in", function(){
      var login = sinon.stub(Omega.Session, 'login')
      index._session_invalid();
      sinon.assert.calledWith(login, sinon.match(function(u){
        return u.id == Omega.Config.anon_user && u.password == Omega.Config.anon_pass;
      }), index.node, sinon.match.func);
    });

    it("handles events", function(){
      var login = sinon.stub(Omega.Session, 'login')
      index._session_invalid();

      var handle_events = sinon.spy(index, 'handle_events');
      var login_cb = login.getCall(0).args[2];
      login_cb({});
      sinon.assert.called(handle_events);
    });

    it("loads universe id", function(){
      var login = sinon.stub(Omega.Session, 'login')

      index._session_invalid();
      var login_cb = login.getCall(0).args[2];

      login_cb({});
      sinon.assert.calledWith(load_universe, index, sinon.match.func);
    });

    it("loads default entities", function(){
      var login = sinon.stub(Omega.Session, 'login')
      index._session_invalid();
      var login_cb = login.getCall(0).args[2];
      login_cb({});

      var load_cb = load_universe.getCall(0).args[1];
      var load_default = sinon.stub(index, '_load_default_entities');
      load_cb();
      sinon.assert.called(load_default);
    });
  });

  describe("#_scene_change", function(){
    var index, change;
    var planet1, planet2, system, old_system,
        ship1, ship2, ship3, ship4, station1, station2, station3;

    before(function(){
      index   = new Omega.Pages.Index();
      index.canvas = Omega.Test.Canvas();
      session = new Omega.Session({user_id : 'user42'});

      planet1 = new Omega.Planet({location : new Omega.Location({})}); 
      planet2 = new Omega.Planet({location : new Omega.Location({})}); 
      system  = new Omega.SolarSystem({id  : 'system42', children : [planet1]});
      old_system  = new Omega.SolarSystem({id  : 'system43', children : [planet2]});

      ship1   = new Omega.Ship({user_id : 'user42', system_id : 'system42',
                                location : new Omega.Location({id : 'l494'})});
      ship2   = new Omega.Ship({user_id : 'user42', system_id : 'system43',
                                location : new Omega.Location({id : 'l495'})});
      ship3   = new Omega.Ship({user_id : 'user43', system_id : 'system42',
                                location : new Omega.Location({id : 'l496'})});
      ship4   = new Omega.Ship({user_id : 'user43', system_id : 'system43',
                                location : new Omega.Location({id : 'l497'})});
      station1 = new Omega.Station({user_id : 'user42', system_id : 'system43', type : 'manufacturing',
                                    location : new Omega.Location({id : 'l498'})});
      station2 = new Omega.Station({user_id : 'user43', system_id : 'system43', type : 'manufacturing',
                                    location : new Omega.Location({id : 'l499'})});
      station3 = new Omega.Station({user_id : 'user43', system_id : 'system42', type : 'manufacturing',
                                    location : new Omega.Location({id : 'l500'})});

      index.session = session;
      index.root = system;
      index.entities = {'sh1' : ship1, 'sh2' : ship2, 'sh3' : ship3, 'sh4' : ship4,
                        'st1' : station1, 'st2' : station2, 'st3' : station3};

      change = {root: system, old_root: old_system}
    });

    after(function(){
      index.canvas.clear();
      if(index.canvas.remove.restore) index.canvas.remove.restore();
      if(index.canvas.add.restore) index.canvas.add.restore();
      if(index.canvas.skybox.set.restore) index.canvas.skybox.set.restore();
    });

    it("creates entity map", function(){
      /// for now just verify first paramater on call to _track_scene_entities
      /// wwhich is the entity map
      var spy = sinon.spy(index, '_track_scene_entities');
      index._scene_change(change)
      var entities = spy.getCall(0).args[0];

      assert(entities.manu).isSameAs(index.all_entities());
      assert(entities.user_owned).isSameAs([ship1, ship2, station1]);
      assert(entities.not_user_owned).isSameAs([ship3, ship4, station2, station3]);
      assert(entities.in_root).isSameAs([ship1, ship3, station3]);
      assert(entities.not_in_root).isSameAs([ship2, ship4, station1, station2]);
      assert(entities.stop_tracking).isSameAs([ship4, station2]);
      assert(entities.start_tracking).isSameAs([ship3, station3]);
    });

    it("starts tracking scene entities", function(){
      var track_scene_entities = sinon.spy(index, '_track_scene_entities');
      index._scene_change(change)
      sinon.assert.calledWith(track_scene_entities,
        sinon.match.object, change.root, change.old_root);
    });

    it("syncs scene entiites", function(){
      var sync_scene_entities = sinon.spy(index, '_sync_scene_entities');
      index._scene_change(change)
      sinon.assert.calledWith(sync_scene_entities,
        sinon.match.object, change.root, change.old_root);
    });

    it("tracks scene planets", function(){
      var track_scene_planets = sinon.spy(index, '_track_scene_planets');
      index._scene_change(change)
      sinon.assert.calledWith(track_scene_planets,
        sinon.match.object, change.root, change.old_root);
    });

    describe("changing scene from galaxy", function(){
      it("removes galaxy from scene entities", function(){
        var remove = sinon.spy(index.canvas, 'remove');
        change.old_root = new Omega.Galaxy();
        index._scene_change(change);
        sinon.assert.calledWith(remove, change.old_root);
      });
    });

    describe("changing scene to galaxy", function(){
      it("adds galaxy to scene entities", function(){
        var add = sinon.spy(index.canvas, 'add');
        change.root = new Omega.Galaxy();
        index._scene_change(change);
        sinon.assert.calledWith(add, change.root);
      });
    });

    it("sets scene skybox background", function(){
      var set_skybox = sinon.spy(index.canvas.skybox, 'set');
      index._scene_change(change);
      sinon.assert.calledWith(set_skybox, change.root.bg);
    });

    it("adds skybox to scene", function(){
      index.canvas.remove(index.canvas.skybox);
      assert(index.canvas.has(index.canvas.skybox.id)).isFalse();
      index._scene_change(change);
      assert(index.canvas.has(index.canvas.skybox.id)).isTrue();
    });
  });

  describe("#_track_scene_entities", function(){
    var index, ship, station, system;
    before(function(){
      index = new Omega.Pages.Index();
      ship  = new Omega.Ship({location : new Omega.Location()});
      station = new Omega.Station({location : new Omega.Location()});
      system = new Omega.SolarSystem();
    });

    it("stops tracking specified entities", function(){
      var entities = {stop_tracking : [ship, station], start_tracking : []};
      var stop_tracking_ship = sinon.spy(index, 'stop_tracking_ship');
      var stop_tracking_station = sinon.spy(index, 'stop_tracking_station');
      index._track_scene_entities(entities, system, system)
      sinon.assert.calledWith(stop_tracking_ship, ship);
      sinon.assert.calledWith(stop_tracking_station, station);
    });

    it("starts tracking specified entities", function(){
      var entities = {start_tracking : [ship, station], stop_tracking : []};
      var track_ship = sinon.spy(index, 'track_ship');
      var track_station = sinon.spy(index, 'track_station');
      index._track_scene_entities(entities, system, system);
      sinon.assert.called(track_ship, ship);
      sinon.assert.called(track_station, station);
    });
  });

  describe("#_track_scene_planets", function(){
    var index, system, old_system, planet, old_planet;

    before(function(){
      index = new Omega.Pages.Index();

      planet = new Omega.Planet({location : new Omega.Location()});
      old_planet = new Omega.Planet({location : new Omega.Location()});

      system = new Omega.SolarSystem({children : [planet]});
      old_system = new Omega.SolarSystem({children: [old_planet]});
    });

    describe("changing from system", function(){
      it("stops tracks planets in old system", function(){
        var stop_tracking_planet = sinon.spy(index, 'stop_tracking_planet');
        index._track_scene_planets({}, system, old_system)
        sinon.assert.calledWith(stop_tracking_planet, old_planet);
      });
    });

    describe("changing to system", function(){
      it("tracks planets in system", function(){
        var track_planet = sinon.spy(index, 'track_planet');
        index._track_scene_planets({}, system, old_system);
        sinon.assert.calledWith(track_planet, planet);
      });
    });
  });

  describe("_sync_scene_entities", function(){
    var index, system, old_system, ship1, ship2, station1;

    before(function(){
      index = new Omega.Pages.Index();
      index.canvas = Omega.Test.Canvas();
      index.session = new Omega.Session({user_id : 'user42'});
      system = new Omega.SolarSystem({ id : 'sys42'});
      old_system = new Omega.SolarSystem();
      ship1 = new Omega.Ship({hp : 50, location : new Omega.Location()});
      ship2 = new Omega.Ship({hp : 0, location : new Omega.Location()});
      station1 = new Omega.Station({location : new Omega.Location()});

      index.canvas.root = system;
      canvas_add = sinon.stub(index.canvas, 'add');
    });

    after(function(){
      index.canvas.clear();
      index.canvas.add.restore();
      if(Omega.Ship.under.restore) Omega.Ship.under.restore();
      if(Omega.Station.under.restore) Omega.Station.under.restore();
    });

    describe("not changing scene to system", function(){
      it("does nothing / just returns", function(){
        index._sync_scene_entities({in_root : [ship1]}, new Omega.Galaxy(), old_system);
        sinon.assert.notCalled(canvas_add);
      });
    });

    it("adds entities in root w/ hp>0 to canvas scene", function(){
      index._sync_scene_entities({in_root : [ship1, ship2]}, system, old_system);
      sinon.assert.calledWith(canvas_add, ship1);
    });

    it("retrieves all ships under root", function(){
      var under = sinon.spy(Omega.Ship, 'under');
      index._sync_scene_entities({in_root : []}, system, old_system);
      sinon.assert.calledWith(under, system.id, index.node, sinon.match.func);
    });

    describe("retrieve ship callback", function(){
      it("processes retrieved scene entities", function(){
        var entity_map = {in_root : [], start_tracking: []};
        var under = sinon.spy(Omega.Ship, 'under');
        index._sync_scene_entities(entity_map, system, old_system);

        var process = sinon.spy(index, '_process_retrieved_scene_entities');
        var under_cb = under.getCall(0).args[2];
        under_cb([ship1]);
        sinon.assert.calledWith(process, [ship1], entity_map);
      });
    });

    it("retrieves all stations under root", function(){
      var under = sinon.spy(Omega.Station, 'under');
      index._sync_scene_entities({in_root : []}, system, old_system);
      sinon.assert.calledWith(under, system.id, index.node, sinon.match.func);
    });

    describe("retrieve station callback", function(){
      it("processes retrieved scene entities", function(){
        var entity_map = {in_root : [], start_tracking: []};
        var under = sinon.spy(Omega.Station, 'under');
        index._sync_scene_entities(entity_map, system, old_system);

        var process = sinon.spy(index, '_process_retrieved_scene_entities');
        var under_cb = under.getCall(0).args[2];
        under_cb([station1]);
        sinon.assert.calledWith(process, [station1], entity_map);
      });
    });
  });

  describe("#_process_retrieved_scene_entities", function(){
    var index, system, ship1, ship2, station1, entities, entity_map,
        canvas_add, canvas_remove;

    before(function(){
      index = new Omega.Pages.Index();
      index.canvas = Omega.Test.Canvas();
      index.session = new Omega.Session({user_id : 'user42'})

      system = new Omega.SolarSystem({id : 'system43'});
      ship1 = new Omega.Ship({ id : 'sh1', user_id : 'user42', system_id : 'system43', hp : 100,
                               location : new Omega.Location()});
      ship2 = new Omega.Ship({ id : 'sh2', user_id : 'user43', system_id : 'system43', hp : 100,
                               location : new Omega.Location()});
      lship2 = new Omega.Ship({ id : 'sh2', user_id : 'user43', system_id : 'system43'});
      ship3 = new Omega.Ship({ id : 'sh3', user_id : 'user43', system_id : 'system43', hp : 0,
                               location : new Omega.Location()});
      ship4 = new Omega.Ship({ id : 'sh4', user_id : 'user43', system_id : 'system43', hp : 100,
                               location : new Omega.Location()});
      ship5 = new Omega.Ship({ id : 'sh5', user_id : 'user43', system_id : 'system43', hp : 100,
                               location : new Omega.Location()});
      station1 = new Omega.Station({ id : 'st1', system_id : 'system43',
                               location : new Omega.Location()});
      station2 = new Omega.Station({ id : 'st2', system_id : 'system43',
                               location : new Omega.Location()});
      entities = [ship1, ship2, ship3, ship4, ship5, station1, station2];
      entity_map = {start_tracking : [ship5, station2]}

      index.entity(lship2.id, lship2);
      index.canvas.root = system;
      index.canvas.entities = [ship2.id, ship4.id];
      canvas_add = sinon.stub(index.canvas, 'add');
      canvas_remove = sinon.stub(index.canvas, 'remove');
    });

    after(function(){
      index.canvas.add.restore();
      index.canvas.remove.restore();
    });

    it("does not process user owned entities", function(){
      index._process_retrieved_scene_entities(entities, entity_map);
      assert(index.entity(ship1.id)).isUndefined();
    });

    it("adds entities to local registry", function(){
      index._process_retrieved_scene_entities(entities, entity_map);
      assert(index.entity(ship2.id)).equals(ship2);
      assert(index.entity(ship3.id)).equals(ship3);
      assert(index.entity(ship4.id)).equals(ship4);
      assert(index.entity(ship5.id)).equals(ship5);
      assert(index.entity(station1.id)).equals(station1);
      assert(index.entity(station2.id)).equals(station2);
    });

    describe("local entity is in scene", function(){
      it("removes entity from scene", function(){
        index._process_retrieved_scene_entities(entities, entity_map);
        sinon.assert.calledWith(canvas_remove, lship2);
      });
    });

    describe("entity has hp > 0 and is under scene root", function(){
      it("adds entity to canvas scene", function(){
        index._process_retrieved_scene_entities(entities, entity_map);
        sinon.assert.calledWith(canvas_add, ship2);
        sinon.assert.calledWith(canvas_add, ship4);
        sinon.assert.calledWith(canvas_add, ship5);
        sinon.assert.calledWith(canvas_add, station1);
        sinon.assert.calledWith(canvas_add, station2);
        sinon.assert.neverCalledWith(canvas_add, ship3);
      });
    });

    describe("not tracking entity", function(){
      it("tracks ships", function(){
        var track_ship = sinon.spy(index, 'track_ship');
        index._process_retrieved_scene_entities(entities, entity_map);
        sinon.assert.calledWith(track_ship, ship2);
        sinon.assert.neverCalledWith(track_ship, ship5);
      });

      it("tracks stations", function(){
        var track_station = sinon.spy(index, 'track_station');
        index._process_retrieved_scene_entities(entities, entity_map);
        sinon.assert.calledWith(track_station, station1);
        sinon.assert.neverCalledWith(track_station, station2);
      });
    });
  });

  describe("#handle_events", function(){
    var index;
    before(function(){
      index = new Omega.Pages.Index();
    });

    it("tracks all motel and manufactured events", function(){
      var events = Omega.UI.CommandTracker.prototype.motel_events.concat(
                   Omega.UI.CommandTracker.prototype.manufactured_events);
      var track = sinon.stub(index.command_tracker, 'track');
      index.handle_events();
      for(var e = 0; e < events.length; e++)
        sinon.assert.calledWith(track, events[e]);
    });
  });

  describe("#process_entities", function(){
    var index, ships;

    before(function(){
      index = new Omega.Pages.Index();
      ships = [new Omega.Ship({id: 'sh1', system_id: 'sys1',
                               location : new Omega.Location()}),
               new Omega.Ship({id: 'sh2', system_id: 'sys2',
                               location : new Omega.Location()})];
    });

/// TODO remove?:
    after(function(){
      if(Omega.SolarSystem.with_id.restore) Omega.SolarSystem.with_id.restore();
    });

    it("invokes process_entity with each entity", function(){
      var process_entity = sinon.stub(index, 'process_entity');
      index.process_entities(ships);
      sinon.assert.calledWith(process_entity, ships[0]);
      sinon.assert.calledWith(process_entity, ships[1]);
    });
  });

  describe("#process_entity", function(){
    var index, ship, station, load_system;
    before(function(){
      index = new Omega.Pages.Index();
      ship  = new Omega.Ship({id: 'sh1', system_id: 'sys1', location : new Omega.Location()});
      station = new Omega.Station({id : 'st1', system_id : 'sys1', location : new Omega.Location()})

      /// stub out load system, galaxy
      load_system = sinon.stub(Omega.UI.Loader, 'load_system');
      sinon.stub(Omega.UI.Loader, 'load_galaxy');
    });

    after(function(){
      Omega.UI.Loader.load_system.restore();
      Omega.UI.Loader.load_galaxy.restore();
    })

    it("stores entity in registry", function(){
      index.process_entity(ship);
      assert(index.entities).includes(ship);
    });

    it("adds entities to entities_list", function(){
      var spy = sinon.spy(index.canvas.controls.entities_list, 'add');
      index.process_entity(ship);
      sinon.assert.calledWith(spy, {id: 'sh1', text: 'sh1', data: ship});
    });

    it("retrieves systems entities are in", function(){
      index.process_entity(ship);
      sinon.assert.calledWith(load_system, 'sys1', index, sinon.match.func);
    });

    it("processes systems retrieved", function(){
      index.process_entity(ship);
      var cb = load_system.getCall(0).args[2];

      spy = sinon.stub(index, 'process_system');
      var sys1 = {};
      cb(sys1);
      sinon.assert.calledWith(spy, sys1);
    });

    it("sets solar system on entity", function(){
      var system = new Omega.SolarSystem();
      Omega.UI.Loader.load_system.restore(); /// XXX
      sinon.stub(Omega.UI.Loader, 'load_system').returns(system);
      index.process_entity(ship);
      assert(ship.solar_system).equals(system);
    });

    it("tracks ships", function(){
      var track_ship = sinon.spy(index, 'track_ship');
      index.process_entity(ship);
      sinon.assert.calledWith(track_ship, ship);
    });

    it("tracks stations", function(){
      var track_station = sinon.spy(index, 'track_station');
      index.process_entity(station);
      sinon.assert.calledWith(track_station, station);
    });
  });

  describe("#track_ship", function(){
    var index, ship, ws_invoke;
    before(function(){
      index = new Omega.Pages.Index();
      ship = new Omega.Ship({id : 'ship42',
                             location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes motel::track_strategy", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_strategy', ship.location.id);
    });

    it("invokes motel::track_stops", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_stops', ship.location.id);
    });

    it("invokes motel::track_movement", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_movement', ship.location.id, index.config.ship_movement);
    });

    it("invokes motel::track_rotation", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::track_rotation', ship.location.id, index.config.ship_rotation);
    });

    it("invokes motel::subscribe_to resource_collected", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'resource_collected');
    });

    it("invokes motel::subscribe_to mining_stopped", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'mining_stopped');
    });

    it("invokes motel::subscribe_to attacked", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'attacked');
    });

    it("invokes motel::subscribe_to attacked_stop", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'attacked_stop');
    });

    it("invokes motel::subscribe_to defended", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'defended');
    });

    it("invokes motel::subscribe_to defended_stop", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'defended_stop');
    });

    it("invokes motel::subscribe_to destroyed_by", function(){
      index.track_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', ship.id, 'destroyed_by');
    });
  });

  describe("#stop_tracking_ship", function(){
    var index, ship, ws_invoke;

    before(function(){
      index = new Omega.Pages.Index();
      ship = new Omega.Ship({id : 'ship42',
                             location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes motel::remove_callbacks", function(){
      index.stop_tracking_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'motel::remove_callbacks', ship.location.id);
    });

    it("invokes manufactured::remove_callbacks", function(){
      index.stop_tracking_ship(ship);
      sinon.assert.calledWith(ws_invoke, 'manufactured::remove_callbacks', ship.id);
    });
  });

  describe("#track_station", function(){
    var index, station, ws_invoke;
    before(function(){
      index   = new Omega.Pages.Index();
      station = new Omega.Station({id : 'station42',
                                   location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes manufactured::subscribe_to construction_complete", function(){
      index.track_station(station);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', station.id, 'construction_complete');
    });

    it("invokes manufactured::subscribe_to partial_construction", function(){
      index.track_station(station);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', station.id, 'partial_construction');
    });
  });

  describe("#stop_tracking_station", function(){
    var index, station, ws_invoke;
    before(function(){
      index   = new Omega.Pages.Index();
      station = new Omega.Station({id : 'station42',
                                   location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes manufactured::remove_callbacks", function(){
      index.stop_tracking_station(station);
      sinon.assert.calledWith(ws_invoke, 'manufactured::remove_callbacks', station.id);
    });
  });

  describe("#track_planet", function(){
    var index, ship, ws_invoke;
    before(function(){
      index = new Omega.Pages.Index();
      planet = new Omega.Planet({id : 'planet42',
                                 location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes motel::track_movement", function(){
      index.track_planet(planet);
      sinon.assert.calledWith(ws_invoke, 'motel::track_movement',
        planet.location.id, index.config.planet_movement);
    });
  });

  describe("#stop_tracking_planet", function(){
    var index, ship, ws_invoke;
    before(function(){
      index = new Omega.Pages.Index();
      planet = new Omega.Planet({id : 'planet42',
                                 location : new Omega.Location({id:'loc42'})}); 
      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("invokes motel::remove_callbacks", function(){
      index.stop_tracking_planet(planet);
      sinon.assert.calledWith(ws_invoke, 'motel::remove_callbacks', planet.location.id);
    });
  });

  describe("#process_system", function(){
    var index, system, load_system;

    before(function(){
      index = new Omega.Pages.Index();
      endpoint = new Omega.SolarSystem({id : 'endpoint'});
      jg = new Omega.JumpGate({endpoint_id : endpoint.id})
      system = new Omega.SolarSystem({id: 'system1', name: 'systema',
                                      parent_id: 'gal1', children: [jg]});
      load_system = sinon.stub(Omega.UI.Loader, 'load_system');
      load_galaxy = sinon.stub(Omega.UI.Loader, 'load_galaxy');
    });

    after(function(){
      if(Omega.UI.Loader.load_system.restore) Omega.UI.Loader.load_system.restore();
      if(Omega.UI.Loader.load_galaxy.restore) Omega.UI.Loader.load_galaxy.restore();
    });

    it("sets solar_system attribute of local registry entities that reference the system", function(){
      var ship1 = new Omega.Ship({id : 'sh1', system_id : system.id})
      index.entity(ship1.id, ship1);
      index.process_system(system);
      assert(ship1.solar_system).equals(system);
    });

    it("updates local registry systems' children from local entity registry", function(){
      index.entity(system.id, system);
      var update_children = sinon.spy(system, 'update_children_from');
      index.process_system(endpoint);
      sinon.assert.calledWith(update_children, sinon.match.array);
    });

    it("adds system to locations_list", function(){
      var spy = sinon.spy(index.canvas.controls.locations_list, 'add');
      index.process_system(system)
      sinon.assert.calledWith(spy, {id: 'system1', text: 'systema', data: system});
    });

    it("adds retrieves galaxy system is in", function(){
      index.process_system(system)
      sinon.assert.calledWith(load_galaxy, system.parent_id, index, sinon.match.func);
    });

    it("processes galaxy", function(){
      index.process_system(system)
      var cb = load_galaxy.getCall(0).args[2];

      spy = sinon.stub(index, 'process_galaxy');
      var galaxy = new Omega.Galaxy();
      cb(galaxy);
      sinon.assert.calledWith(spy, galaxy);
    });

    describe("galaxy already retrieved", function(){
      it("updates galaxy children from local entity registry", function(){
        var galaxy = new Omega.Galaxy({id : system.parent_id});
        index.entity(galaxy.id, galaxy)
        Omega.UI.Loader.load_galaxy.restore();

        var set_children = sinon.spy(galaxy, 'set_children_from');
        index.process_system(system);
        sinon.assert.calledWith(set_children, sinon.match.array);
      });
    });

    it("retrieves missing jg endpoints", function(){
      index.process_system(system);
      sinon.assert.calledWith(load_system, endpoint.id, index, sinon.match.func);
    });

    it("processes system with jg endpoints retrieved", function(){
      index.process_system(system);

      var process_system = sinon.stub(index, 'process_system');
      var retrieval_cb = load_system.getCall(0).args[2];
      retrieval_cb(endpoint);
      sinon.assert.calledWith(process_system, endpoint);
    });

    it("updates system children from local entities registry", function(){
      var update_children = sinon.spy(system, 'update_children_from');
      index.process_system(system);
      sinon.assert.calledWith(update_children, index.all_entities());
    });
  });

  describe("#process_galaxy", function(){
    var index;

    before(function(){
      index = new Omega.Pages.Index();
    });

    it("adds galaxy to locations_list", function(){
      var index = new Omega.Pages.Index();
      var galaxy = new Omega.Galaxy({id: 'galaxy1', name: 'galaxya'});

      var spy = sinon.spy(index.canvas.controls.locations_list, 'add');
      index.process_galaxy(galaxy)
      sinon.assert.calledWith(spy, {id: 'galaxy1', text: 'galaxya', data: galaxy});
    });

    it("sets galaxy children from local entities registry", function(){
      var galaxy = new Omega.Galaxy({id: 'galaxy1'});
      var set_children = sinon.spy(galaxy, 'set_children_from');
      index.process_galaxy(galaxy);
      sinon.assert.calledWith(set_children, sinon.match.array);
    });
  });

  it("has a status indicator", function(){
    var index = new Omega.Pages.Index();
    assert(index.status_indicator).isOfType(Omega.UI.StatusIndicator);
  });

  it("has an effects player", function(){
    var index = new Omega.Pages.Index();
    assert(index.effects_player).isOfType(Omega.UI.EffectsPlayer);
    assert(index.effects_player.page).equals(index);
  });

  it("has an index dialog", function(){
    var index = new Omega.Pages.Index();
    assert(index.dialog).isOfType(Omega.UI.IndexDialog);
    assert(index.dialog.page).isSameAs(index);
  });

  it("has an index nav", function(){
    var index = new Omega.Pages.Index();
    assert(index.nav).isOfType(Omega.UI.IndexNav);
    assert(index.nav.page).isSameAs(index);
  });

  it("has a canvas", function(){
    var index = new Omega.Pages.Index();
    assert(index.canvas).isOfType(Omega.UI.Canvas);
  });

  describe("#entity", function(){
    it("gets/sets entity", function(){
      var index = new Omega.Pages.Index();
      var foo = {};
      index.entity('foo', foo);
      assert(index.entity('foo')).equals(foo);
    });
  });

  describe("#all_entities", function(){
    it("returns array of all entities", function(){
      var ship1 = new Omega.Ship({id : 'sh1'});
      var ship2 = new Omega.Ship({id : 'sh2'});
      var index = new Omega.Pages.Index();
      index.entities = {'sh1' : ship1, 'sh2' : ship2};
      assert(index.all_entities()).isSameAs([ship1, ship2]);
    });
  });

  describe("#wire_up", function(){
    var index,
        wire_nav, wire_dialog, wire_canvas;

    before(function(){
      index = new Omega.Pages.Index();
      wire_nav    = sinon.stub(index.nav,    'wire_up');
      wire_dialog = sinon.stub(index.dialog, 'wire_up');
      wire_canvas = sinon.stub(index.canvas, 'wire_up');
    });

    it("wires up navigation", function(){
      index.wire_up();
      sinon.assert.called(wire_nav);
    });

    it("wires up dialog", function(){
      index.wire_up();
      sinon.assert.called(wire_dialog);
    });

    it("wires up canvas", function(){
      index.wire_up();
      sinon.assert.called(wire_canvas);
    });

    it("wires up canvas scene change", function(){
      assert(index.canvas._listeners).isUndefined();
      index.wire_up();
      assert(index.canvas._listeners['set_scene_root'].length).equals(1);
    });

    describe("on canvas scene change", function(){
      it("invokes page.scene_change", function(){
        index.wire_up();
        var scene_changed_cb = index.canvas._listeners['set_scene_root'][0];
        var scene_change = sinon.stub(index, '_scene_change');
        scene_changed_cb({data: 'change'});
        sinon.assert.calledWith(scene_change, 'change')
      });
    })

    it("instructs status indicator to follow node", function(){
      var spy   = sinon.spy(index.status_indicator, 'follow_node');
      index.wire_up();
      sinon.assert.calledWith(spy, index.node);
    });
  });
});});
