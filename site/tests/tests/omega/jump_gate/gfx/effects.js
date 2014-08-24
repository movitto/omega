/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfxEffects", function(){
describe("Omega.JumpGateGfxEffects", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.location.set(100, -100, 200);
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      jg.init_gfx();
      sinon.spy(jg.lamp, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.lamp.run_effects);
    });

    it("runs particles effects", function(){
      jg.init_gfx();
      sinon.spy(jg.particles, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.particles.run_effects);
    });

    it("runs mesh effects", function(){
      jg.init_gfx();
      sinon.spy(jg.mesh, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.mesh.run_effects);
    });
  });
});});
