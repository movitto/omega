// Test mixin usage through ship
pavlov.specify("Omega.ShipGfxMovement", function(){
describe("Omega.ShipGfxMovement", function(){
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
      ship.location.set_orientation(1, 0, 0);
      ship.location.movement_strategy = {speed : 10};
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

  describe("#_run_follow_movement", function(){
    var distance, page, tracked;

    before(function(){
      distance = Omega.Config.follow_distance;

      tracked = Omega.Gen.ship();
      tracked.location.set(0, 0, 0);

      ship.init_gfx();
      ship.location.movement_strategy = 
        {json_class : 'Motel::MovementStrategies::Follow',
         tracked_location_id : tracked.id,
         distance : distance};
      ship.location.set(distance + 100, 0, 0);

      page = new Omega.Pages.Test();
      page.entity(tracked.id, tracked);
    });

    describe("ship is orienting itself towards target", function(){
      it("_runs_rotation_movement", function(){
        ship.location.movement_strategy.point_to_target = true;
        sinon.spy(ship, '_run_rotation_movement');
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship._run_rotation_movement, page, 1000);
      });
    });

    describe("ship is not facing target", function(){
      it("faces target / runs rotation movement", function(){
        ship.location.movement_strategy.point_to_target = false;
        ship.location.set_orientation(1, 0, 0);

        sinon.spy(ship.location, 'face_target');
        sinon.spy(ship, '_run_rotation_movement');

        ship.last_moved = new Date(new Date() - 1000);
        ship._run_follow_movement(page);
        sinon.assert.called(ship.location.face_target);
        sinon.assert.calledWith(ship._run_rotation_movement, page, 1000)
      });
    });

    describe("ship is not on target", function(){
      it("moves ship towards target", function(){
        var coordinates = ship.location.coordinates();
        ship.location.set_orientation(-1, 0, 0);

        var dist = ship.location.distance_from(tracked.location);
        var dx   = (tracked.location.x - ship.location.x) / dist;
        var dy   = (tracked.location.y - ship.location.y) / dist;
        var dz   = (tracked.location.z - ship.location.z) / dist;

        ship.location.movement_strategy.speed = 1;
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        ship._run_follow_movement(page);
        assert(ship.location.x).equals(coordinates[0] + dx);
        assert(ship.location.y).equals(coordinates[1] + dy);
        assert(ship.location.z).equals(coordinates[2] + dz);
      });
    });

    describe("ship is on target and target is moving", function(){
      it("matches target speed", function(){
        ship.location.movement_strategy.speed = 100;
        tracked.location.movement_strategy.speed = 10;
        tracked.location.set(ship.location.coordinates());
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago

        sinon.spy(ship.location, 'move_linear')
        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship.location.move_linear, 10);
      });
    });

    describe("ship is on target and target not moving", function(){
      it("orbits target", function(){
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        tracked.location.set(ship.location.coordinates());
        ship.location.movement_strategy.speed = 10;

        sinon.spy(ship, '_run_rotation_movement');
        sinon.spy(ship.location, 'move_linear');

        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship._run_rotation_movement, page, 1000, true);
        sinon.assert.calledWith(ship.location.move_linear, 10);
      });
    });

    it("updates gfx", function(){
      sinon.stub(ship, 'update_gfx');
      ship._run_follow_movement(page);
      sinon.assert.called(ship.update_gfx);
    });

    it("sets last movement to now", function(){
      ship._run_follow_movement(page);
      assert(ship.last_moved).isNotNull();
    });

    it("dispatches movement event", function(){
      var spy = sinon.spy();
      ship.addEventListener('movement', spy);
      ship._run_follow_movement(page);
      sinon.assert.called(spy);
    });
  });

  //describe("#_run_figure8_movement") // NIY

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
