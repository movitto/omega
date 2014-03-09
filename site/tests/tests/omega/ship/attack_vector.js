pavlov.specify("Omega.ShipAttackVector", function(){
describe("Omega.ShipAttackVector", function(){
  it("has a SPE Group instance", function(){
    var vector = new Omega.ShipAttackVector({config: Omega.Config});
    assert(vector.particles).isOfType(ShaderParticleGroup);
    assert(vector.particles.emitters.length).equals(1);
  });

  describe("#update", function(){
    var loc, vector;

    before(function(){
      loc = new Omega.Location();
      loc.set(200, -200, 50);

      vector = new Omega.ShipAttackVector({config: Omega.Config});
      vector.omega_entity = {location : loc};
    });

    it("sets attack vector position", function(){
      vector.update();
      assert(vector.particles.emitters[0].position.x).equals(loc.x);
      assert(vector.particles.emitters[0].position.y).equals(loc.y);
      assert(vector.particles.emitters[0].position.z).equals(loc.z);
    });
  });
});}); /// Omega.ShipAttackVector

