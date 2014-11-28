pavlov.specify("Omega.Pages.IndexEntityProcessor", function(){
describe("Omega.Pages.IndexEntityProcessor", function(){
  describe("#_add_nav_entity", function(){
    var page, ship;

    before(function(){
      page = $.extend({canvas : new Omega.UI.Canvas()}, Omega.Pages.IndexEntityProcessor);
      ship = Omega.Gen.ship();
    });

    it("adds entity to entities list", function(){
      page._add_nav_entity(ship);
      assert(page.canvas.controls.entities_list.has(ship.id)).isTrue();
      assert(page.canvas.controls.entities_list.list().length).equals(1);
    });

    describe("entities list already has entity", function(){
      it("does not add entity to list", function(){
        page._add_nav_entity(ship);
        page._add_nav_entity(ship);
        assert(page.canvas.controls.entities_list.list().length).equals(1);
      });
    })
  });

  describe("#_add_nav_system", function(){
    var page, system;

    before(function(){
      page = $.extend({canvas : new Omega.UI.Canvas()}, Omega.Pages.IndexEntityProcessor);
      system = Omega.Gen.solar_system();
    });

    it("adds system to locations list", function(){
      page._add_nav_system(system);
      assert(page.canvas.controls.locations_list.has(system.id)).isTrue();
      assert(page.canvas.controls.locations_list.list().length).equals(1);
    });

    describe("locations list already has system", function(){
      it("does not add system to list", function(){
        page._add_nav_system(system);
        page._add_nav_system(system);
        assert(page.canvas.controls.locations_list.list().length).equals(1);
      });
    });
  });

  describe("#_add_nav_galaxy", function(){
    var page, galaxy;

    before(function(){
      page = $.extend({canvas : new Omega.UI.Canvas()}, Omega.Pages.IndexEntityProcessor);
      galaxy = Omega.Gen.galaxy();
    });

    it("adds galaxy to locations list", function(){
      page._add_nav_system(galaxy);
      assert(page.canvas.controls.locations_list.has(galaxy.id)).isTrue();
      assert(page.canvas.controls.locations_list.list().length).equals(1);
    });

    describe("locations list already has galaxy", function(){
      it("does not add galaxy to list", function(){
        page._add_nav_system(galaxy);
        page._add_nav_system(galaxy);
        assert(page.canvas.controls.locations_list.list().length).equals(1);
      });
    });
  });

  describe("#_store_entity", function(){
    var page, entity;

    before(function(){
      page = $.extend({}, Omega.Pages.HasRegistry, Omega.Pages.IndexEntityProcessor);
      page.init_registry();
      entity = Omega.Gen.ship();
    });

    describe("prexisting local entity", function(){
      it("updates local entity", function(){
        var local = Omega.Gen.ship();
        page.entity(entity.id, local);
        sinon.stub(local, 'update');
        page._store_entity(entity);
        sinon.assert.calledWith(local.update, entity);
      });
    });

    it("stores local entity in registry", function(){
      page._store_entity(entity);
      assert(page.entity(entity.id)).equals(entity);
    });
  });

  describe("#process_entities", function(){
    var entities;

    before(function(){
      sinon.stub(Omega.Pages.IndexEntityProcessor, 'process_entity');
      entities = [Omega.Gen.ship(), Omega.Gen.ship()];
    });

    after(function(){
      Omega.Pages.IndexEntityProcessor.process_entity.restore();
    });

    it("invokes process_entity with each entity", function(){
      Omega.Pages.IndexEntityProcessor.process_entities(entities);
      sinon.assert.calledWith(Omega.Pages.IndexEntityProcessor.process_entity,
                              entities[0]);
      sinon.assert.calledWith(Omega.Pages.IndexEntityProcessor.process_entity,
                              entities[1]);
    });
  });
  
  describe("#_load_entity_system", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
      sinon.stub(Omega.Pages.IndexEntityProcessor, 'process_system');
    });

    after(function(){
      Omega.UI.Loader.load_system.restore();
      Omega.Pages.IndexEntityProcessor.process_system.restore();
    });

    it("retrieves system entity is in", function(){
      sinon.stub(Omega.UI.Loader, 'load_system');
      Omega.Pages.IndexEntityProcessor._load_entity_system(ship);
      sinon.assert.calledWith(Omega.UI.Loader.load_system, ship.system_id,
                              Omega.Pages.IndexEntityProcessor, sinon.match.func);
    });

    describe("entity system already retrieved", function(){
      it("updates entity system", function(){
        var sys = Omega.Gen.solar_system();
        sinon.stub(Omega.UI.Loader, 'load_system').returns(sys);
        sinon.stub(ship, 'update_system');
        Omega.Pages.IndexEntityProcessor._load_entity_system(ship);
        sinon.assert.calledWith(ship.update_system, sys);
      });
    });

    describe("entity system loaded/retrieved", function(){
      it("processes system", function(){
        var sys = Omega.Gen.solar_system();
        sinon.stub(Omega.UI.Loader, 'load_system');
        Omega.Pages.IndexEntityProcessor._load_entity_system(ship);
        Omega.UI.Loader.load_system.omega_callback()(sys)
        sinon.assert.calledWith(Omega.Pages.IndexEntityProcessor.process_system, sys);
      });
    });
  });

  describe("#process_entity", function(){
/// TODO update
    var entity;

    before(function(){
      page   = $.extend({canvas : new Omega.UI.Canvas()},
                        Omega.Pages.IndexEntityProcessor,
                        Omega.EntityTracker,
                        Omega.Pages.SceneTracker,
                        Omega.Pages.TracksCam);
      page.canvas.root = Omega.Gen.solar_system();
      entity = Omega.Gen.ship({system_id : page.canvas.root.id});

      sinon.stub(page, '_store_entity').returns(entity);
      sinon.stub(page, '_add_nav_entity');
      sinon.stub(page, '_load_entity_system');
      sinon.stub(page, 'track_entity');
      sinon.stub(page, '_scale_entity');
      sinon.stub(page.canvas, 'add');
    });

    it("stores entity in registry", function(){
      page.process_entity(entity);
      sinon.assert.calledWith(page._store_entity, entity);
    });

    it("adds entities to entities_list", function(){
      page.process_entity(entity);
      sinon.assert.calledWith(page._add_nav_entity, entity);
    });

    it("retrieves system entity is in", function(){
      page.process_entity(entity);
      sinon.assert.calledWith(page._load_entity_system, entity);
    });

    //it("adds entity to canvas") /// NIY
    //it("scales entity"); /// NIY

    it("tracks entity", function(){
      page.process_entity(entity);
      sinon.assert.calledWith(page.track_entity, entity);
    });

    //describe("entity is not alive", function(){
    //  var ship;

    //  before(function(){
    //    ship = Omega.Gen.ship();
    //    ship.hp = 0;
    //  });

    //  //it("does not add to canvas"); // NIY
    //  //it("does not track entity") /// NIY
    //  //it("does not add to navigation") /// NIY
    //});
  });

  describe("#_update_system_references", function(){
    var page, system;

    before(function(){
      page = $.extend({}, Omega.Pages.IndexEntityProcessor, Omega.Pages.HasRegistry);
      page.init_registry();
      system = Omega.Gen.solar_system();
    });

    it("updates system children w/ system", function(){
      var ship1 = Omega.Gen.ship({system_id : system.id});
      var ship2 = Omega.Gen.ship({system_id : Omega.Gen.solar_system().id});
      page.entity(ship1.id, ship1);
      page.entity(ship2.id, ship2);

      sinon.stub(ship1, 'update_system');
      sinon.stub(ship2, 'update_system');
      page._update_system_references(system);
      sinon.assert.calledWith(ship1.update_system, system);
      sinon.assert.notCalled(ship2.update_system);
    });

    it("updates all systems children from entities list", function(){
      var sys = Omega.Gen.solar_system();
      page.entity(sys.id, sys);

      var entities = [];
      sinon.stub(page, 'all_entities').returns(entities);

      sinon.stub(sys, 'update_children_from');
      page._update_system_references(system);
      sinon.assert.calledWith(sys.update_children_from, entities);
    });
  });

  describe("#_load_system_galaxy", function(){
    var page, system;

    before(function(){
      page = $.extend({node : new Omega.Node(),
                       canvas : new Omega.UI.Canvas()},
                       Omega.Pages.IndexEntityProcessor, Omega.Pages.HasRegistry);
      page.init_registry();
      system = Omega.Gen.solar_system();
    });

    after(function(){
      Omega.UI.Loader.load_galaxy.restore();
    });

    it("retrieves system galaxy", function(){
      sinon.stub(Omega.UI.Loader, 'load_galaxy');
      page._load_system_galaxy(system);
      sinon.assert.calledWith(Omega.UI.Loader.load_galaxy,
                              system.parent_id, page, sinon.match.func);
    });

    describe("system galaxy already retrieved", function(){
      it("updates all galaxy children from entities list", function(){
        var galaxy = Omega.Gen.galaxy();
        sinon.stub(Omega.UI.Loader, 'load_galaxy').returns(galaxy);
        var entities = [];
        sinon.stub(page, 'all_entities').returns(entities);
        sinon.stub(galaxy, 'set_children_from');
        page._load_system_galaxy(system);
        sinon.assert.calledWith(galaxy.set_children_from, entities);
      })
    });

    describe("system galaxy loaded/retrieved", function(){
      it("processes galaxy", function(){
        var galaxy = Omega.Gen.galaxy();
        sinon.stub(Omega.UI.Loader, 'load_galaxy');
        page._load_system_galaxy(system);
        sinon.stub(page, 'process_galaxy');
        Omega.UI.Loader.load_galaxy.omega_callback()(galaxy)
        sinon.assert.calledWith(page.process_galaxy, galaxy);
      })
    });
  });

  describe("#_load_system_interconns", function(){
    var system, gate1, gate2;

    before(function(){
      gate1  = Omega.Gen.jump_gate({endpoint_id : 'systemABC'});
      gate2  = Omega.Gen.jump_gate({endpoint_id : 'systemDEF'});
      system = Omega.Gen.solar_system({children : [gate1, gate2]});

      sinon.stub(Omega.UI.Loader, 'load_system');
      sinon.stub(Omega.Pages.IndexEntityProcessor, 'process_system');
    })

    after(function(){
      Omega.UI.Loader.load_system.restore();
      Omega.Pages.IndexEntityProcessor.process_system.restore();
    });

    it("loads system jump gate endpoints", function(){
      Omega.Pages.IndexEntityProcessor._load_system_interconns(system);
      sinon.assert.calledWith(Omega.UI.Loader.load_system, gate1.endpoint_id,
                              Omega.Pages.IndexEntityProcessor, sinon.match.func);
      sinon.assert.calledWith(Omega.UI.Loader.load_system, gate2.endpoint_id,
                              Omega.Pages.IndexEntityProcessor, sinon.match.func);
    });

    describe("endpoint system retreived", function(){
      it("processes system", function(){
        var retrieved = Omega.Gen.solar_system();
        Omega.Pages.IndexEntityProcessor._load_system_interconns(system);
        Omega.UI.Loader.load_system.omega_callback()(retrieved);
        sinon.assert.calledWith(Omega.Pages.IndexEntityProcessor.process_system, retrieved);
      });
    });
  });

  describe("#_process_system_on_refresh", function(){
    var system;

    before(function(){
      system = Omega.Gen.solar_system();
      sinon.stub(Omega.Pages.IndexEntityProcessor, 'process_system');
    });

    after(function(){
      Omega.Pages.IndexEntityProcessor.process_system.restore();
    });

    describe("system refresh callback already exists", function(){
      it("does nothing / just returns", function(){
        system._process_on_refresh = 'anything';
        Omega.Pages.IndexEntityProcessor._process_system_on_refresh(system);
        assert(system._process_on_refresh).equals('anything');
        assert(system).doesNotHandleEvent('refreshed');
      });
    });

    it("registers new system refresh event listener", function(){
      Omega.Pages.IndexEntityProcessor._process_system_on_refresh(system);
      assert(typeof(system._process_on_refresh)).equals("function");
      assert(system).handlesEvent('refreshed');
    })

    describe("on system refresh", function(){
      it("processes system", function(){
        Omega.Pages.IndexEntityProcessor._process_system_on_refresh(system);
        system.dispatchEvent({type : 'refreshed', data : system});
        sinon.assert.calledWith(Omega.Pages.IndexEntityProcessor.process_system, system);
      });
    })
  });

  describe("#process_system", function(){
    var page, system;

    before(function(){
      page = $.extend({}, Omega.Pages.IndexEntityProcessor, Omega.Pages.HasRegistry);
      page.init_registry();
      system = Omega.Gen.solar_system();

      sinon.stub(page, '_add_nav_system');
      sinon.stub(page, '_update_system_references');
      sinon.stub(page, '_load_system_galaxy');
      sinon.stub(page, '_load_system_interconns');
      sinon.stub(page, '_process_system_on_refresh');
    });

    it("adds system to nav", function(){
      page.process_system(system);
      sinon.assert.calledWith(page._add_nav_system, system);
    });

    it("updates system references", function(){
      page.process_system(system);
      sinon.assert.calledWith(page._update_system_references, system);
    });

    it("loads system galaxy", function(){
      page.process_system(system);
      sinon.assert.calledWith(page._load_system_galaxy, system);
    });

    it("loads system interconns", function(){
      page.process_system(system);
      sinon.assert.calledWith(page._load_system_interconns, system);
    });

    it("updates system references", function(){
      sinon.stub(system, 'update_children_from');
      page.process_system(system);
      sinon.assert.calledWith(system.update_children_from, page.all_entities());
    });

    it("wires up system refresh processing", function(){
      page.process_system(system);
      sinon.assert.calledWith(page._process_system_on_refresh, system);
    });
  });

  describe("#_process_galaxy_on_refresh", function(){
    var galaxy;

    before(function(){
      galaxy = Omega.Gen.galaxy();
      sinon.stub(Omega.Pages.IndexEntityProcessor, 'process_galaxy');
    });

    after(function(){
      Omega.Pages.IndexEntityProcessor.process_galaxy.restore();
    });

    describe("galaxy refresh callback already exists", function(){
      it("does nothing / just returns", function(){
        galaxy._process_on_refresh = 'anything';
        Omega.Pages.IndexEntityProcessor._process_galaxy_on_refresh(galaxy);
        assert(galaxy._process_on_refresh).equals('anything');
        assert(galaxy).doesNotHandleEvent('refreshed');
      });
    });

    it("registers new galaxy refresh event listener", function(){
      Omega.Pages.IndexEntityProcessor._process_galaxy_on_refresh(galaxy);
      assert(typeof(galaxy._process_on_refresh)).equals("function");
      assert(galaxy).handlesEvent('refreshed');
    })

    describe("on galaxy refresh", function(){
      it("processes galaxy", function(){
        Omega.Pages.IndexEntityProcessor._process_galaxy_on_refresh(galaxy);
        galaxy.dispatchEvent({type : 'refreshed', data : galaxy});
        sinon.assert.calledWith(Omega.Pages.IndexEntityProcessor.process_galaxy, galaxy);
      });
    })
  });

  describe("#_load_galaxy_interconns", function(){
    before(function(){
      sinon.stub(Omega.UI.Loader, 'load_interconnects');
    });

    after(function(){
      Omega.UI.Loader.load_interconnects.restore();
    });

    it("uses loaded to load_interconnects", function(){
      var galaxy = Omega.Gen.galaxy();
      Omega.Pages.IndexEntityProcessor._load_galaxy_interconns(galaxy);
      sinon.assert.calledWith(Omega.UI.Loader.load_interconnects, galaxy,
                              Omega.Pages.IndexEntityProcessor, sinon.match.func);
    });
  });

  describe("#process_galaxy", function(){
    var page, galaxy;

    before(function(){
      page = $.extend({}, Omega.Pages.IndexEntityProcessor, Omega.Pages.HasRegistry);
      page.init_registry();
      galaxy = Omega.Gen.galaxy();

      sinon.stub(page, '_add_nav_galaxy');
      sinon.stub(page, '_load_galaxy_interconns');
      sinon.stub(page, '_process_galaxy_on_refresh');
    });

    it("adds galaxy to nav", function(){
      page.process_galaxy(galaxy);
      sinon.assert.calledWith(page._add_nav_galaxy, galaxy);
    });

    it("updates galaxy references", function(){
      sinon.stub(galaxy, 'set_children_from');
      page.process_galaxy(galaxy);
      sinon.assert.calledWith(galaxy.set_children_from, page.all_entities());
    });

    it("loads galaxy interconns", function(){
      page.process_galaxy(galaxy);
      sinon.assert.calledWith(page._load_galaxy_interconns, galaxy);
    });

    it("wires up galaxy refresh processing", function(){
      page.process_galaxy(galaxy);
      sinon.assert.calledWith(page._process_galaxy_on_refresh, galaxy);
    });
  });
});});
