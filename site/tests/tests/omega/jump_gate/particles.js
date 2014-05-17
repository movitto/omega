pavlov.specify("Omega.JumpGateParticles", function(){
describe("Omega.JumpGateParticles", function(){
  var gate_particles;

  before(function(){
    gate_particles = new Omega.JumpGateParticles({config: Omega.Config});
  });

  it("has a Omega.JumpGateParticles instance", function(){
    assert(gate_particles.particles.mesh).isOfType(THREE.ParticleSystem);
  });

  describe("#clone", function(){
    it("returns new particles instance", function(){
      var cloned = gate_particles.clone(Omega.Config);
      assert(cloned).isOfType(Omega.JumpGateParticles);
      assert(cloned).isNotEqualTo(gate_particles);
    });
  });

  describe("#update", function(){
    it("sets emitter position to jump gate scene location + offset", function(){
      var jg = Omega.Gen.jump_gate();
      jg.location.set(-100, 200, 300);
      gate_particles.omega_entity = jg;
      gate_particles.update();

      var pos = gate_particles.particles.emitters[0].position;
      assert(pos.x).equals(-100 + gate_particles.offset[0]);
      assert(pos.y).equals( 200 + gate_particles.offset[1]);
      assert(pos.z).equals( 300 + gate_particles.offset[2]);
    });
  });

  describe("#run_effects", function(){
    it("runs particle effects", function(){
      var delta = {};
      sinon.stub(gate_particles.clock, 'getDelta').returns(delta);
      sinon.stub(gate_particles.particles, 'tick');
      gate_particles.run_effects();
      sinon.assert.calledWith(gate_particles.particles.tick, delta);
    });
  });
});});
