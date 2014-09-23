// Test mixin usage through ship
pavlov.specify("Omega.ShipLinearMovement", function(){
describe("Omega.ShipLinearMovement", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#_run_linear_movement", function(){
    before(function(){
      ship.init_gfx();
    });

    it("moves ship along linear path", function(){
      ship.location.set(0, 0, 0);
      ship.location.movement_strategy = {speed : 10, dx : 1, dy : 0, dz: 0};
      ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
      ship._run_linear_movement();
      assert(ship.location.coordinates()).isSameAs([10, 0, 0]);
    });

    it("updates gfx", function(){
      sinon.stub(ship, 'update_gfx');
      ship._run_linear_movement();
      sinon.assert.called(ship.update_gfx);
    });

    it("sets last movement to now", function(){
      ship._run_linear_movement();
      assert(ship.last_moved).isNotNull();
    });

    it("dispatches movement event", function(){
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._run_linear_movement();
      sinon.assert.called(spy);
    });
  });
});});
