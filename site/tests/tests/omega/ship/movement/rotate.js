// Test mixin usage through ship
pavlov.specify("Omega.ShipRotationMovement", function(){
describe("Omega.ShipRotationMovement", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#_run_rotation_movement", function(){
    var page;

    before(function(){
      ship.init_gfx();
      ship.location.set_orientation(1, 0, 0);
      ship.location.movement_strategy = {rot_x : 0, rot_y : 0, rot_z : 1, rot_theta : Math.PI/2};
      page = new Omega.Pages.Test();
    });

    it("rotates ship according to rotation strategy", function(){
      ship._run_rotation_movement(page, 1000);
      var orientation = ship.location.orientation();
      assert(orientation[0]).close(0, 0.00001);
      assert(orientation[1]).close(1);
      assert(orientation[2]).close(0);
    });

    it("updates gfx", function(){
      sinon.stub(ship, 'update_gfx');
      ship._run_rotation_movement();
      sinon.assert.called(ship.update_gfx);
    });

    it("sets last movement to now", function(){
      ship._run_rotation_movement();
      assert(ship.last_moved).isNotNull();
    });

    it("dispatches movement event", function(){
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._run_rotation_movement();
      sinon.assert.called(spy);
    });
  });
});});
