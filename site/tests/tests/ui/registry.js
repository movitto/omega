pavlov.specify("Omega.UI.Registry", function(){
describe("Omega.UI.Registry", function(){
  describe("#entity", function(){
    it("gets/sets entity", function(){
      var registry = new Omega.UI.Registry();
      var foo = {};
      registry.entity('foo', foo);
      assert(registry.entity('foo')).equals(foo);
    });
  });

  describe("#all_entities", function(){
    it("returns array of all entities", function(){
      var ship1 = new Omega.Ship({id : 'sh1'});
      var ship2 = new Omega.Ship({id : 'sh2'});
      var registry = new Omega.UI.Registry();
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
      var registry = new Omega.UI.Registry({entities : [ship, sys1, sys2, gal1]});
      assert(registry.systems()).isSameAs([sys1, sys2]);
    });
  });

  describe("#galaxies", function(){
    it("returns all galaxies in the entities list", function(){
      var ship = Omega.Gen.ship();
      var sys1 = Omega.Gen.solar_system();
      var gal1 = Omega.Gen.galaxy();
      var gal2 = Omega.Gen.galaxy();
      var registry = new Omega.UI.Registry({entities : [ship, sys1, gal1, gal2]});
      assert(registry.galaxies()).isSameAs([gal1, gal2]);
    });
  });
});});
