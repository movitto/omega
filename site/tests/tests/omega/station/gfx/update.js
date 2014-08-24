// Test mixin usage through ship
pavlov.specify("Omega.StationGfxUpdater", function(){
describe("Omega.StationGfxUpdater", function(){
  var station;

  before(function(){
    station = Omega.Gen.station({type: 'manufacturing'});
    station.location = new Omega.Location({x: 100, y: -100, z: 200});
    station.location.movement_strategy = {json_class : 'Motel::MovementStrategies::Stopped'};
  });

  describe("#update_gfx", function(){
    it("sets position tracker location from scene location", function(){
      var loc = new Omega.Location();
      loc.set(-123, 234, -321);
      sinon.stub(station, 'scene_location').returns(loc);

      station.update_gfx();
      var position = station.position_tracker().position;
      assert(position.x).equals(-123);
      assert(position.y).equals(234);
      assert(position.z).equals(-321);
    });

    describe("station is stopped", function(){
      before(function(){
        sinon.stub(station.location, 'is_stopped').returns(true);
      });

      it("removes orbit line", function(){
        sinon.stub(station, '_has_orbit_line').returns(true);
        sinon.stub(station, '_rm_orbit_line');
        station.update_gfx();
        sinon.assert.called(station._rm_orbit_line);
      });

      it("resets run movement method", function(){
        station.update_gfx();
        assert(station._run_movement_effects).equals(station._run_movement);
      });
    });

    describe("station is not stopped", function(){
      before(function(){
        sinon.stub(station.location, 'is_stopped').returns(false);
        sinon.stub(station, '_has_orbit_line').returns(false);
      });

      it("calculates orbit", function(){
        sinon.spy(station, '_calc_orbit');
        station.update_gfx();
        sinon.assert.called(station._calc_orbit);
      });

      it("calculates current orbit angle", function(){
        sinon.spy(station, '_current_orbit_angle');
        station.update_gfx();
        sinon.assert.called(station._current_orbit_angle);
      });

      it("Adds orbit line", function(){
        sinon.spy(station, '_add_orbit_line');
        station.update_gfx();
        sinon.assert.called(station._add_orbit_line);
      });

      it("sets movement method to orbit movement method", function(){
        station.init_gfx();
        station.update_gfx();
        assert(station._run_movement_effects).equals(station._run_orbit_movement);
      });
    });
  });

  describe("#update_construction_gfx", function(){
    it("updates station construction bar", function(){
      station.init_gfx();
      var update = sinon.spy(station.construction_bar, 'update');
      station.update_construction_gfx();
      sinon.assert.called(update);
    });
  });
});});
