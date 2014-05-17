// TODO test independently (currently testing through index page mixin)
pavlov.specify("Omega.UI.Tracker", function(){
describe("Omega.UI.Tracker", function(){
  describe("#entity_map", function(){
    var page, system, other_system;
    var ship1, ship2, ship3, ship4;
    var station1, station2, station3;

    before(function(){
      system = Omega.Gen.solar_system();
      other_system = Omega.Gen.solar_system();

      page = $.extend({canvas : new Omega.UI.Canvas()},
                      Omega.UI.Tracker, new Omega.UI.Registry());
      page.canvas.root = Omega.Gen.solar_system({id : system.id})
      page.session = new Omega.Session({user_id : 'user42'});

      ship1 = Omega.Gen.ship({user_id   : 'user42',
                              system_id : system.id});
      ship2 = Omega.Gen.ship({user_id   : 'user42',
                              system_id : other_system.id});
      ship3 = Omega.Gen.ship({user_id   : 'user43',
                              system_id : system.id});
      ship4 = Omega.Gen.ship({user_id   : 'user43',
                              system_id : other_system.id});

      station1 = Omega.Gen.station({user_id   : 'user42',
                                    system_id : other_system.id});
      station2 = Omega.Gen.station({user_id   : 'user43',
                                    system_id : other_system.id});
      station3 = Omega.Gen.station({user_id   : 'user43',
                                    system_id : system.id});

      var entities = [ship1, ship2, ship3, ship4, station1, station2, station3];
      for(var e = 0; e < entities.length; e++)
        page.entity(entities[e].id, entities[e]);
    });

    it("returns all manu registry entities", function(){
      assert(page.entity_map(system).manu).isSameAs(page.all_entities());
    });

    it("returns registry entities owned by current user", function(){
      assert(page.entity_map(system).user_owned).
        isSameAs([ship1, ship2, station1]);
    });

    it("returns registry entities not owned by current user", function(){
      assert(page.entity_map(system).not_user_owned).
        isSameAs([ship3, ship4, station2, station3]);
    });

  //// TODO
    //it("returns registry entities to stop tracking (not user owned, not in current root)", function(){
    //  assert(page.entity_map(system).start_tracking).
    //    isSameAs([ship3, station3]);
    //});
  });

  describe("#track_system_events", function(){
    var page, system;
    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.UI.Tracker);
      system = Omega.Gen.solar_system();
      sinon.stub(page.node, 'ws_invoke');
    });

    it("subscribes to system_jump events to new scene root", function(){
      page.track_system_events(system);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'manufactured::subscribe_to',
                              'system_jump', 'to', system.id);
    });
  });

  describe("#stop_tracking_system_events", function(){
    var page;
    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.UI.Tracker);
      sinon.stub(page.node, 'ws_invoke');
    });

    it("unsubscribes to system_jump events", function(){
      page.stop_tracking_system_events();
      sinon.assert.calledWith(page.node.ws_invoke,
                              'manufactured::unsubscribe', 'system_jump');
    });
  });

  describe("#stop_tracking_scene_entities", function(){
    var ship, station, entities;

    before(function(){
      ship = Omega.Gen.ship();
      station = Omega.Gen.ship();
      entities = {stop_tracking : [ship, station]};

      sinon.stub(Omega.UI.Tracker, 'stop_tracking_entity');
    });

    after(function(){
      Omega.UI.Tracker.stop_tracking_entity.restore();
    });

    it("stops tracking specified entities", function(){
      Omega.UI.Tracker.stop_tracking_scene_entities(entities);
      sinon.assert.calledWith(Omega.UI.Tracker.stop_tracking_entity, ship);
      sinon.assert.calledWith(Omega.UI.Tracker.stop_tracking_entity, station);
    });
  });

  describe("#sync_scene_planets", function(){
    var page, system;
    var response;

    before(function(){
      planet1 = Omega.Gen.planet();
      planet2 = Omega.Gen.planet();
      system  = Omega.Gen.solar_system({children : [planet1, planet2]});

      page = $.extend({node : new Omega.Node(),
                       canvas : new Omega.UI.Canvas()}, Omega.UI.Tracker);
      page.canvas.root = system;

      sinon.stub(page.canvas, 'reload');
      sinon.stub(page.node, 'http_invoke');

      response = {result : Omega.Gen.planet().location};
    });

    it("updates planet locations", function(){
      page.sync_scene_planets(system);
      sinon.assert.calledWith(page.node.http_invoke, 'motel::get_location',
                              'with_id', planet1.location.id, sinon.match.func);
      sinon.assert.calledWith(page.node.http_invoke, 'motel::get_location',
                              'with_id', planet2.location.id, sinon.match.func);
    });

    it("sets planet location", function(){
      page.sync_scene_planets(system);
      page.node.http_invoke.omega_callback()(response);
      assert(planet1.location).isSameAs(response.result);
    });

    describe("root entity is not canvas root", function(){
      it("does not reload planet", function(){
        page.canvas.root = Omega.Gen.galaxy();
        page.sync_scene_planets(system);
        page.node.http_invoke.omega_callback()(response);
        page.node.http_invoke.omega_callback(1)(response);
        sinon.assert.notCalled(page.canvas.reload);
      });
    });

    it("reloads planet in scene", function(){
      page.sync_scene_planets(system);
      page.node.http_invoke.omega_callback()(response);
      sinon.assert.calledWith(page.canvas.reload, planet1, sinon.match.func);
    });

    it("updates planet gfx", function(){
      sinon.stub(planet1, 'update_gfx');
      page.sync_scene_planets(system);
      page.node.http_invoke.omega_callback()(response);
      page.canvas.reload.omega_callback()();
      sinon.assert.called(planet1.update_gfx);
    });
  });

  describe("sync_scene_entities", function(){
    var page, system;
    var ship, station, entities;

    before(function(){
      page = $.extend({node : new Omega.Node(),
                       canvas : new Omega.UI.Canvas()}, Omega.UI.Tracker);

      system   = Omega.Gen.solar_system();
      ship     = Omega.Gen.ship();
      station  = Omega.Gen.station();
      entities = {in_root : [ship, station]};

      sinon.stub(page.canvas, 'add');
      sinon.stub(Omega.Ship, 'under');
      sinon.stub(Omega.Station, 'under');
    });

    after(function(){
      Omega.Ship.under.restore();
      Omega.Station.under.restore();
    });

    it("retrieves all ships under root", function(){
      var cb = sinon.spy();
      page.sync_scene_entities(system, entities, cb);
      sinon.assert.calledWith(Omega.Ship.under, system.id, page.node, cb);
    });

    it("retrieves all stations under root", function(){
      var cb = sinon.spy();
      page.sync_scene_entities(system, entities, cb);
      sinon.assert.calledWith(Omega.Station.under, system.id, page.node, cb);
    });
  });

  describe("#track_entity", function(){
    before(function(){
      sinon.stub(Omega.UI.Tracker, 'track_ship');
      sinon.stub(Omega.UI.Tracker, 'track_station');
    });

    after(function(){
      Omega.UI.Tracker.track_ship.restore();
      Omega.UI.Tracker.track_station.restore();
    });

    it("tracks specified ship/station", function(){
      var ship = Omega.Gen.ship();
      var station = Omega.Gen.station();
      Omega.UI.Tracker.track_entity(ship);
      Omega.UI.Tracker.track_entity(station);
      sinon.assert.calledWith(Omega.UI.Tracker.track_ship, ship);
      sinon.assert.calledWith(Omega.UI.Tracker.track_station, station);
    });
  });

  describe("#stop_tracking_entity", function(){
    before(function(){
      sinon.stub(Omega.UI.Tracker, 'stop_tracking_ship');
      sinon.stub(Omega.UI.Tracker, 'stop_tracking_station');
    });

    after(function(){
      Omega.UI.Tracker.stop_tracking_ship.restore();
      Omega.UI.Tracker.stop_tracking_station.restore();
    });

    it("stops tracking specified ship/station", function(){
      var ship = Omega.Gen.ship();
      var station = Omega.Gen.station();
      Omega.UI.Tracker.stop_tracking_entity(ship);
      Omega.UI.Tracker.stop_tracking_entity(station);
      sinon.assert.calledWith(Omega.UI.Tracker.stop_tracking_ship, ship);
      sinon.assert.calledWith(Omega.UI.Tracker.stop_tracking_station, station);
    });
  })

  describe("#track_ship", function(){
    var page, ship;

    before(function(){
      page = $.extend({config: Omega.Config,
                       node : new Omega.Node()}, Omega.UI.Tracker);
      ship = Omega.Gen.ship();
      sinon.stub(page.node, 'ws_invoke');
    });

    it("invokes motel::track_strategy", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'motel::track_strategy', ship.location.id);
    });

    it("invokes motel::track_stops", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'motel::track_stops', ship.location.id);
    });

    it("invokes motel::track_movement", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'motel::track_movement',
                              ship.location.id, page.config.ship_movement);
    });

    it("invokes motel::track_rotation", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'motel::track_rotation',
                              ship.location.id, page.config.ship_rotation);
    });

    it("invokes motel::subscribe_to resource_collected", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'manufactured::subscribe_to',
                              ship.id, 'resource_collected');
    });

    it("invokes motel::subscribe_to mining_stopped", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'manufactured::subscribe_to',
                              ship.id, 'mining_stopped');
    });

    it("invokes motel::subscribe_to attacked", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              ship.id, 'attacked');
    });

    it("invokes motel::subscribe_to attacked_stop", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              ship.id, 'attacked_stop');
    });

    it("invokes motel::subscribe_to defended", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              ship.id, 'defended');
    });

    it("invokes motel::subscribe_to defended_stop", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              ship.id, 'defended_stop');
    });

    it("invokes motel::subscribe_to destroyed_by", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              ship.id, 'destroyed_by');
    });
  });

  describe("#stop_tracking_ship", function(){
    var page, ship;

    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.UI.Tracker);
      ship = Omega.Gen.ship();
      sinon.stub(page.node, 'ws_invoke');
    });

    it("invokes motel::remove_callbacks", function(){
      page.stop_tracking_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'motel::remove_callbacks', ship.location.id);
    });

    it("invokes manufactured::remove_callbacks", function(){
      page.stop_tracking_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::remove_callbacks', ship.id);
    });
  });

  describe("#track_station", function(){
    var page, station;

    before(function(){
      page = $.extend({node : new Omega.Node(),
                       config : Omega.Config}, Omega.UI.Tracker);
      station = Omega.Gen.station();
      sinon.stub(page.node, 'ws_invoke');
    });

    it("invokes manufactured::subscribe_to construction_complete", function(){
      page.track_station(station);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              station.id, 'construction_complete');
    });

    it("invokes manufactured::subscribe_to construction_failed", function(){
      page.track_station(station);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              station.id, 'construction_failed');
    });

    it("invokes manufactured::subscribe_to partial_construction", function(){
      page.track_station(station);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::subscribe_to',
                              station.id, 'partial_construction');
    });
  });

  describe("#stop_tracking_station", function(){
    var page, station;

    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.UI.Tracker);
      station = Omega.Gen.station();
      sinon.stub(page.node, 'ws_invoke');
    });

    it("invokes manufactured::remove_callbacks", function(){
      page.stop_tracking_station(station);
      sinon.assert.calledWith(page.node.ws_invoke, 
                              'manufactured::remove_callbacks', station.id);
    });
  });

  describe("#track_user_events", function(){
    var page, station;

    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.UI.Tracker);
      sinon.stub(page.node, 'ws_invoke');
    });

    it("invokes missions::subscribe to user victory", function(){
      page.track_user_events('user1');
      sinon.assert.calledWith(page.node.ws_invoke,
                              'missions::subscribe_to',
                              'victory', 'user_id', 'user1');
    });

    it("invokes missions::subscribe to user failure", function(){
      page.track_user_events('user1');
      sinon.assert.calledWith(page.node.ws_invoke,
                              'missions::subscribe_to',
                              'failed', 'user_id', 'user1');
    });
  });
});});
