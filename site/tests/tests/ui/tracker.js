// TODO test independently (currently testing through index page mixin)
pavlov.specify("Omega.UI.Tracker", function(){
describe("Omega.UI.Tracker", function(){
  describe("#track_system_events", function(){
    var index, http_invoke, system;
    before(function(){
      index  = new Omega.Pages.Index();
      system = new Omega.SolarSystem({id : 'system1'});

      ws_invoke = sinon.stub(index.node, 'ws_invoke');
    });

    it("unsubscribes to system_jump events", function(){
      index.track_system_events(system, system);
      sinon.assert.calledWith(ws_invoke, 'manufactured::unsubscribe', 'system_jump');
    });

    it("subscribes to system_jump events to new scene root", function(){
      index.track_system_events(system, system);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', 'system_jump', 'to', system.id);
    });
  });

  describe("#track_scene_entities", function(){
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
      index.track_scene_entities(system, entities);
      sinon.assert.calledWith(stop_tracking_ship, ship);
      sinon.assert.calledWith(stop_tracking_station, station);
    });

    it("starts tracking specified entities", function(){
      var entities = {start_tracking : [ship, station], stop_tracking : []};
      var track_ship = sinon.spy(index, 'track_ship');
      var track_station = sinon.spy(index, 'track_station');
      index.track_scene_entities(system, entities);
      sinon.assert.called(track_ship, ship);
      sinon.assert.called(track_station, station);
    });
  });

  describe("#sync_scene_planets", function(){
    var index, http_invoke, canvas_reload,
        system, old_system, planet, old_planet, loc;

    before(function(){
      index = new Omega.Pages.Index();

      /// stub out call to server and reload
      http_invoke = sinon.stub(index.node, 'http_invoke');
      canvas_reload = sinon.stub(index.canvas, 'reload');

      planet = new Omega.Planet({location : new Omega.Location()});
      old_planet = new Omega.Planet({location : new Omega.Location()});

      system = new Omega.SolarSystem({children : [planet]});
      old_system = new Omega.SolarSystem({children: [old_planet]});

      index.canvas.root = system;
      loc = new Omega.Location();
    });

    describe("changing to system", function(){
      it("updates planet locations", function(){
        index.sync_scene_planets(system);
        sinon.assert.calledWith(http_invoke, 'motel::get_location',
                                'with_id', planet.location.id, sinon.match.func)
        var cb = http_invoke.getCall(0).args[3];

        cb({result : loc})
        assert(planet.location).isSameAs(loc);
      });

      it("reloads canvas in scene", function(){
        index.sync_scene_planets(system);
        var cb = http_invoke.getCall(0).args[3];
        cb({result : loc})
        sinon.assert.calledWith(canvas_reload, planet, sinon.match.func)
      })

      it("updates planet gfx", function(){
        index.sync_scene_planets(system);
        var cb = http_invoke.getCall(0).args[3];
        cb({result : loc})

        var update_gfx = sinon.stub(planet, 'update_gfx');
        cb = canvas_reload.getCall(0).args[1];
        cb();
        sinon.assert.called(update_gfx)
      });
    });
  });

  describe("sync_scene_entities", function(){
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
        index.sync_scene_entities(new Omega.Galaxy(), {in_root : [ship1]});
        sinon.assert.notCalled(canvas_add);
      });
    });

    it("adds entities in root w/ hp>0 to canvas scene", function(){
      index.sync_scene_entities(system, {in_root : [ship1, ship2]});
      sinon.assert.calledWith(canvas_add, ship1);
    });

    it("retrieves all ships under root", function(){
      var cb = function(){};
      var under = sinon.spy(Omega.Ship, 'under');
      index.sync_scene_entities(system, {in_root : []}, cb);
      sinon.assert.calledWith(under, system.id, index.node, cb);
    });

    it("retrieves all stations under root", function(){
      var cb = function(){};
      var under = sinon.spy(Omega.Station, 'under');
      index.sync_scene_entities(system, {in_root : []}, cb);
      sinon.assert.calledWith(under, system.id, index.node, cb);
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

    it("invokes manufactured::subscribe_to construction_failed", function(){
      index.track_station(station);
      sinon.assert.calledWith(ws_invoke, 'manufactured::subscribe_to', station.id, 'construction_failed');
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
});});
