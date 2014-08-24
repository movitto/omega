pavlov.specify("Omega.ShipAttackVector", function(){
describe("Omega.ShipAttackVector", function(){
  it("has a THREE.Line instance", function(){
    var vector = new Omega.ShipAttackVector({});
    assert(vector.line).isOfType(THREE.Line);
  });

  describe("#update", function(){
    var loc, vector;

    before(function(){
      loc = new Omega.Location();
      loc.set(200, -200, 50);

      vector = new Omega.ShipAttackVector({});
      vector.omega_entity = {location : loc};
    });

    //it("updates target location"); // NIY
  });
});}); /// Omega.ShipAttackVector

