pavlov.specify("Omega.JumpGateParticles", function(){
describe("Omega.JumpGateParticles", function(){
  it("has a Omega.JumpGateParticles instance", function(){
    var gate_particles = new Omega.JumpGateParticles({config: Omega.Config});
    assert(gate_particles.particles.mesh).isOfType(THREE.ParticleSystem);
  });
});});
