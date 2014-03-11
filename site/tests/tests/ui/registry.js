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
});});
