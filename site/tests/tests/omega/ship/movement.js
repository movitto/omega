// Test mixin usage through ship
pavlov.specify("Omega.ShipMovement", function(){
describe("Omega.ShipMovement", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#_no_movement", function(){
    it("does nothing / just returns", function(){
      var coordinates = ship.location.coordinates();
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._no_movement();
      sinon.assert.notCalled(spy);
      assert(ship.location.coordinates()).isSameAs(coordinates);
    });
  });
});});
