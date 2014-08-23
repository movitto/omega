// TODO test independently (currently testing through index page mixin)
pavlov.specify("Omega.EntityTracker", function(){
describe("Omega.EntityTracker", function(){
  describe("#track_system_events", function(){
    var page, system;
    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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

      sinon.stub(Omega.EntityTracker, 'stop_tracking_entity');
    });

    after(function(){
      Omega.EntityTracker.stop_tracking_entity.restore();
    });

    it("stops tracking specified entities", function(){
      Omega.EntityTracker.stop_tracking_scene_entities(entities);
      sinon.assert.calledWith(Omega.EntityTracker.stop_tracking_entity, ship);
      sinon.assert.calledWith(Omega.EntityTracker.stop_tracking_entity, station);
    });
  });

  describe("#sync_scene_planets", function(){
    var page, system, planet1, planet2;
    var response;

    before(function(){
      planet1 = Omega.Gen.planet();
      planet2 = Omega.Gen.planet();
      system  = Omega.Gen.solar_system({children : [planet1, planet2]});

      page = $.extend({node : new Omega.Node(),
                       canvas : new Omega.UI.Canvas()}, Omega.EntityTracker);
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
                       canvas : new Omega.UI.Canvas()}, Omega.EntityTracker);

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
      sinon.stub(Omega.EntityTracker, 'track_ship');
      sinon.stub(Omega.EntityTracker, 'track_station');
    });

    after(function(){
      Omega.EntityTracker.track_ship.restore();
      Omega.EntityTracker.track_station.restore();
    });

    it("tracks specified ship/station", function(){
      var ship = Omega.Gen.ship();
      var station = Omega.Gen.station();
      Omega.EntityTracker.track_entity(ship);
      Omega.EntityTracker.track_entity(station);
      sinon.assert.calledWith(Omega.EntityTracker.track_ship, ship);
      sinon.assert.calledWith(Omega.EntityTracker.track_station, station);
    });
  });

  describe("#stop_tracking_entity", function(){
    before(function(){
      sinon.stub(Omega.EntityTracker, 'stop_tracking_ship');
      sinon.stub(Omega.EntityTracker, 'stop_tracking_station');
    });

    after(function(){
      Omega.EntityTracker.stop_tracking_ship.restore();
      Omega.EntityTracker.stop_tracking_station.restore();
    });

    it("stops tracking specified ship/station", function(){
      var ship = Omega.Gen.ship();
      var station = Omega.Gen.station();
      Omega.EntityTracker.stop_tracking_entity(ship);
      Omega.EntityTracker.stop_tracking_entity(station);
      sinon.assert.calledWith(Omega.EntityTracker.stop_tracking_ship, ship);
      sinon.assert.calledWith(Omega.EntityTracker.stop_tracking_station, station);
    });
  })

  describe("#track_ship", function(){
    var page, ship;

    before(function(){
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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
                              ship.location.id, Omega.Config.ship_movement);
    });

    it("invokes motel::track_rotation", function(){
      page.track_ship(ship);
      sinon.assert.calledWith(page.node.ws_invoke,
                              'motel::track_rotation',
                              ship.location.id, Omega.Config.ship_rotation);
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
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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
      page = $.extend({node : new Omega.Node()}, Omega.EntityTracker);
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
