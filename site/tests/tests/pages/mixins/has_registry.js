pavlov.specify("Omega.Pages.HasRegistry", function(){
describe("Omega.Pages.HasRegistry", function(){
  var registry;

  before(function(){
    registry = $.extend({}, Omega.Pages.HasRegistry);
  });

  describe("#init_registry", function(){
    it("initializes registry entities", function(){
      registry.init_registry();
      assert(registry.entities).isSameAs({});
    });
  });

  describe("#clear_entities", function(){
    it("clears all entities", function(){
      var foo = {};
      registry.init_registry();
      registry.entity('foo', foo);
      registry.clear_entities();
      assert(registry.entity('foo')).isUndefined();
      assert(registry.entities).isSameAs({});
    });
  })

  describe("#entity", function(){
    it("gets/sets entity", function(){
      var foo = {};
      registry.init_registry();
      registry.entity('foo', foo);
      assert(registry.entity('foo')).equals(foo);
    });
  });

  describe("#all_entities", function(){
    it("returns array of all entities", function(){
      var ship1 = new Omega.Ship({id : 'sh1'});
      var ship2 = new Omega.Ship({id : 'sh2'});
      registry.entities = {'sh1' : ship1, 'sh2' : ship2};
      assert(registry.all_entities()).isSameAs([ship1, ship2]);
    });
  });

  describe("#systems", function(){
    it("returns all systems in the entities list", function(){
      var ship = Omega.Gen.ship();
      var sys1 = Omega.Gen.solar_system();
      var sys2 = Omega.Gen.solar_system();
      var gal1 = Omega.Gen.galaxy();
      registry.entities = {'sh1' : ship, 'sys1' : sys1, 'sys2' : sys2, 'gal1' : gal1};
      assert(registry.systems()).isSameAs([sys1, sys2]);
    });
  });

  describe("#galaxies", function(){
    it("returns all galaxies in the entities list", function(){
      var ship = Omega.Gen.ship();
      var sys1 = Omega.Gen.solar_system();
      var gal1 = Omega.Gen.galaxy();
      var gal2 = Omega.Gen.galaxy();
      registry.entities = {'sh1': ship, 'sys1' : sys1, 'gal1': gal1, 'gal2' : gal2};
      assert(registry.galaxies()).isSameAs([gal1, gal2]);
    });
  });

  describe("#manu_entities", function(){
    it("returns all manufactured entities in registry", function(){
      var ship1 = Omega.Gen.ship();
      var ship2 = Omega.Gen.ship();
      var sys1  = Omega.Gen.solar_system();
      registry.entities = {'sh1': ship1, 'sh2' : ship2, 'sys1' : sys1};
      assert(registry.manu_entities()).isSameAs([ship1, ship2]);
    });
  });

  describe("#entity_map", function(){
    var system, other_system;
    var ship1, ship2, ship3, ship4;
    var station1, station2, station3;

    before(function(){
      registry.init_registry();
      registry.session = new Omega.Session({user_id : 'user42'});

      system = Omega.Gen.solar_system();
      other_system = Omega.Gen.solar_system();

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
        registry.entity(entities[e].id, entities[e]);
    });

    it("returns all manu registry entities", function(){
      assert(registry.entity_map(system).manu).isSameAs(registry.all_entities());
    });

    it("returns registry entities owned by current user", function(){
      assert(registry.entity_map(system).user_owned).
        isSameAs([ship1, ship2, station1]);
    });

    it("returns registry entities not owned by current user", function(){
      assert(registry.entity_map(system).not_user_owned).
        isSameAs([ship3, ship4, station2, station3]);
    });

    //// TODO
    //it("returns registry entities to stop tracking (not user owned, not in current root)", function(){
    //  assert(registry.entity_map(system).start_tracking).
    //    isSameAs([ship3, station3]);
    //});
  });
});});
