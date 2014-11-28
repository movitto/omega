/// Test Mixin usage through Planet
pavlov.specify("Omega.PlanetGfxUpdater", function(){
describe("Omega.PlanetGfxUpdater", function(){
  describe("#update_gfx", function(){
    it("sets mesh position from planet location", function(){
      var planet = Omega.Test.entities().planet;
      planet.location = new Omega.Location({x : 20, y : 30, z : -20});
      planet.update_gfx();
      assert(planet.position_tracker().position.x).equals( 20);
      assert(planet.position_tracker().position.y).equals( 30);
      assert(planet.position_tracker().position.z).equals(-20);
    });
  });
});});
