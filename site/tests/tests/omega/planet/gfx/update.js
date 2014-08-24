/// Test Mixin usage through Planet
pavlov.specify("Omega.PlanetGfxUpdater", function(){
describe("Omega.PlanetGfxUpdater", function(){
  describe("#update_gfx", function(){
    it("sets mesh position from planet location", function(){
      var planet = Omega.Test.entities().planet;
      planet.location = new Omega.Location({x : 20, y : 30, z : -20});
      planet.update_gfx();
      assert(planet.mesh.tmesh.position.x).equals( 20);
      assert(planet.mesh.tmesh.position.y).equals( 30);
      assert(planet.mesh.tmesh.position.z).equals(-20);
    });
  });
});});
