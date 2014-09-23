// Test mixin usage through ship
pavlov.specify("Omega.ShipFollowMovement", function(){
describe("Omega.ShipFollowMovement", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
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

    describe("target is moving", function(){
      before(function(){
        tracked.location.movement_strategy.speed = 42;
      });

      it("faces target", function(){
        sinon.stub(ship.location, 'facing_target').returns(false);
        sinon.spy(ship.location, 'face_target');
        sinon.spy(ship, '_rotate');

        ship.last_moved = new Date(new Date() - 1000);
        ship._run_follow_movement(page);
        sinon.assert.called(ship.location.face_target);
        sinon.assert.calledWith(ship._rotate, 1000)
      });

      it("moves towards target", function(){
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        sinon.spy(ship, '_move_linear')
        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship._move_linear, 1000);
      });

      it("matches target speed", function(){
        ship.location.movement_strategy.speed = 100;
        tracked.location.set(ship.location.coordinates());
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago

        sinon.spy(ship.location, 'move_linear')
        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship.location.move_linear, 42);
      });
    });

    describe("target not moving", function(){
      before(function(){
        tracked.location.movement_strategy.speed = 0;
      });

      it("orbits target", function(){
        var coords = ship.location.coordinates();
        ship.last_moved = new Date(new Date() - 1000); // last moved 1s ago
        tracked.location.set(coords);
        ship.location.movement_strategy.speed = 10;

        sinon.stub(ship, '_orbit_angle_from_coords').returns(0.42);
        sinon.stub(ship, '_coords_from_orbit_angle').returns([0, 4, 2]);

        sinon.spy(ship.location, 'face');
        sinon.spy(ship, '_rotate');
        sinon.spy(ship.location, 'update_ms_acceleration');
        sinon.spy(ship, '_move_linear');

        ship._run_follow_movement(page);
        sinon.assert.calledWith(ship._orbit_angle_from_coords, coords);
        sinon.assert.calledWith(ship._coords_from_orbit_angle, 0.42 + Math.PI / 6);
        sinon.assert.calledWith(ship.location.face, [0, 4, 2]);
        sinon.assert.calledWith(ship._rotate, 1000);
        sinon.assert.calledWith(ship.location.update_ms_acceleration);
        sinon.assert.calledWith(ship._move_linear, 1000);
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
});});
