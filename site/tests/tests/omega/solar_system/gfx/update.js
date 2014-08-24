/// Test Mixin usage through SolarSystem
pavlov.specify("Omega.SolarSystemGfxUpdater", function(){
describe("Omega.SolarSystemGfxUpdater", function(){
  var system;

  before(function(){
    system = new Omega.SolarSystem();
    system.location = new Omega.Location({x: 50, y:60, z:-75});
  });

  describe("#update_gfx", function(){
    it("sets position tracker position", function(){
      system.init_gfx();
      system.location.set(100, -200, 300);
      system.update_gfx();
      assert(system.position_tracker().position.x).equals(100);
      assert(system.position_tracker().position.y).equals(-200);
      assert(system.position_tracker().position.z).equals(300);
    });
  });
});});
