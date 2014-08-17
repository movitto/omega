pavlov.specify("Omega.JumpGateParticles", function(){
describe("Omega.JumpGateParticles", function(){
  var gate_particles;

  before(function(){
    gate_particles = new Omega.JumpGateParticles({config: Omega.Config});
  });

  it("has a Omega.JumpGateParticles instance", function(){
    assert(gate_particles.particles.mesh).isOfType(THREE.ParticleSystem);
    assert(gate_particles.particles.mesh.position.toArray()).isSameAs(gate_particles.offset);
  });

  describe("#clone", function(){
    it("returns new particles instance", function(){
      var cloned = gate_particles.clone(Omega.Config);
      assert(cloned).isOfType(Omega.JumpGateParticles);
      assert(cloned).isNotEqualTo(gate_particles);
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
