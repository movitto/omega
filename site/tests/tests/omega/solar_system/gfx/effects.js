/// Test Mixin usage through SolarSystem
pavlov.specify("Omega.SolarSystemGfxEffects", function(){
describe("Omega.SolarSystemGfxEffects", function(){
  var system;

  before(function(){
    system = new Omega.SolarSystem();
    system.location = new Omega.Location({x: 50, y:60, z:-75});
  });

  describe("#run_effects", function(){
    it("runs interconnect effects", function(){
      system.init_gfx();
      sinon.stub(system.interconns, 'run_effects');
      system.run_effects();
      sinon.assert.calledWith(system.interconns.run_effects);
    });

    it("runs particles effects", function(){
      system.init_gfx();
      sinon.stub(system.particles, 'run_effects');
      system.run_effects();
      sinon.assert.calledWith(system.particles.run_effects);
    });
  });
});});
