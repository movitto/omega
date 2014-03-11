// TODO test independently (currently testing through index page mixin)
pavlov.specify("Omega.UI.CanvasTracker", function(){
describe("Omega.UI.CanvasTracker", function(){
  describe("#scene_change", function(){
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
      /// for now just verify first paramater on call to track_scene_entities
      /// wwhich is the entity map
      var spy = sinon.spy(index, 'track_scene_entities');
      index.scene_change(change)
      var entities = spy.getCall(0).args[1];

      assert(entities.manu).isSameAs(index.all_entities());
      assert(entities.user_owned).isSameAs([ship1, ship2, station1]);
      assert(entities.not_user_owned).isSameAs([ship3, ship4, station2, station3]);
      assert(entities.in_root).isSameAs([ship1, ship3, station3]);
      assert(entities.not_in_root).isSameAs([ship2, ship4, station1, station2]);
      assert(entities.stop_tracking).isSameAs([ship4, station2]);
      assert(entities.start_tracking).isSameAs([ship3, station3]);
    });

    it("starts tracking scene events", function(){
      var track_system_events = sinon.spy(index, 'track_system_events');
      index.scene_change(change);
      sinon.assert.calledWith(track_system_events, change.root);
    });

    it("starts tracking scene entities", function(){
      var track_scene_entities = sinon.spy(index, 'track_scene_entities');
      index.scene_change(change)
      sinon.assert.calledWith(track_scene_entities, change.root, sinon.match.object);
    });

    it("syncs scene entities", function(){
      var sync_scene_entities = sinon.spy(index, 'sync_scene_entities');
      index.scene_change(change)
      sinon.assert.calledWith(sync_scene_entities, change.root, sinon.match.object);
    });

    describe("scene entity callback", function(){
      it("processes retrieved scene entities", function(){
        var sync_scene_entities = sinon.spy(index, 'sync_scene_entities');
        index.scene_change(change)

        var process = sinon.spy(index, '_process_retrieved_scene_entities');
        var sync_cb = sync_scene_entities.getCall(0).args[2];
        sync_cb([ship1])
        sinon.assert.calledWith(process, [ship1], sinon.match.object);
      });
    });


    it("syncs scene planets", function(){
      var sync_scene_planets = sinon.spy(index, 'sync_scene_planets');
      index.scene_change(change)
      sinon.assert.calledWith(sync_scene_planets, change.root);
    });

    describe("changing scene from galaxy", function(){
      it("removes galaxy from scene entities", function(){
        var remove = sinon.spy(index.canvas, 'remove');
        change.old_root = new Omega.Galaxy();
        index.scene_change(change);
        sinon.assert.calledWith(remove, change.old_root);
      });
    });

    describe("changing scene to galaxy", function(){
      it("adds galaxy to scene entities", function(){
        var add = sinon.spy(index.canvas, 'add');
        change.root = new Omega.Galaxy();
        index.scene_change(change);
        sinon.assert.calledWith(add, change.root);
      });
    });

    it("sets scene skybox background", function(){
      var set_skybox = sinon.spy(index.canvas.skybox, 'set');
      index.scene_change(change);
      sinon.assert.calledWith(set_skybox, change.root.bg);
    });

    it("adds skybox to scene", function(){
      index.canvas.remove(index.canvas.skybox);
      assert(index.canvas.has(index.canvas.skybox.id)).isFalse();
      index.scene_change(change);
      assert(index.canvas.has(index.canvas.skybox.id)).isTrue();
    });
  });

  describe("#_process_retrieved_scene_entities", function(){
    var index, system, ship1, ship2, station1, entities, entity_map,
        canvas_add, canvas_remove, list_add;

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

      index.entity(system.id, system);
      index.entity(lship2.id, lship2);
      index.canvas.root = system;
      index.canvas.entities = [ship2.id, ship4.id];
      canvas_add = sinon.stub(index.canvas, 'add');
      canvas_remove = sinon.stub(index.canvas, 'remove');
      list_add = sinon.stub(index.canvas.controls.entities_list, 'add');

      index.canvas.controls.entities_list.clear();
    });

    after(function(){
      index.canvas.add.restore();
      index.canvas.remove.restore();
      index.canvas.controls.entities_list.add.restore();
    });

    it("sets entity solar system", function(){
      index._process_retrieved_scene_entities(entities, entity_map);
      for(var e = 0; e < entities.length; e++){
        assert(entities[e].solar_system).equals(system);
      }
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

    describe("entity is alive, under scene root, and not in scene", function(){
      it("adds entity to canvas scene", function(){
        index._process_retrieved_scene_entities(entities, entity_map);
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

    describe("entity list does not have entity", function(){
      it("adds entity to list", function(){
        index._process_retrieved_scene_entities(entities, entity_map);
        sinon.assert.called(list_add);
        var ids = ['sh2', 'sh4', 'sh5', 'st1', 'st2'];
        for(var i = 0; i < ids.length; i++){
          var call = list_add.getCall(i);
          assert(call.args[0].id).equals(ids[i]);
          assert(call.args[0].text).equals(ids[i]);
        }
      })
    })
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
});});
