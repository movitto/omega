pavlov.specify("Omega.ShipMiningVector", function(){
describe("Omega.ShipMiningVector", function(){
  it("has a SPE Group instance", function(){
    var vector = new Omega.ShipMiningVector({config: Omega.Config});
    assert(vector.particles).isOfType(SPE.Group);
    assert(vector.particles.emitters.length).
      equals(Omega.ShipMiningVector.prototype.num_emitters);
  });

  describe("#update", function(){
    var loc, vector;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});
      vector = new Omega.ShipMiningVector({config: Omega.Config});
      vector.omega_entity = {location : loc};
    });

    //it("sets mining vector velocity", function(){ /// NIY
    //});
  });
});}); /// Omega.ShipMiningVector
