// Test mixin usage through ship
pavlov.specify("Omega.StationGfxEffects", function(){
describe("Omega.StationGfxEffects", function(){
  var station;

  before(function(){
    station = Omega.Gen.station({type: 'manufacturing'});
    station.location = new Omega.Location({x: 100, y: -100, z: 200});
    station.location.movement_strategy = {json_class : 'Motel::MovementStrategies::Stopped'};
  });

  describe("#_run_movement", function(){
    it("does nothing / does not move station", function(){
      var coordinates = station.location.coordinates();
      station._run_movement();
      assert(station.location.coordinates()).isSameAs(coordinates);
    });
  });

  describe("#_run_orbit_movement", function(){
    it("updates station orbit angle", function(){
      station.last_moved = new Date(new Date() - 1000); // last moved 1s ago
      station.location.movement_strategy = {speed : 1.57};
      station._orbit_angle = 0;
      sinon.stub(station, 'update_gfx'); /// stub out update gfx
      sinon.stub(station, '_set_orbit_angle');
      station._run_orbit_movement();
      assert(station._orbit_angle).equals(1.57);
      sinon.assert.calledWith(station._set_orbit_angle, 1.57);
    });

    it("sets last moved", function(){
      sinon.stub(station, '_set_orbit_angle'); /// stub out set_orbit_angle
      station._run_orbit_movement();
      assert(station.last_moved).isNotNull();
    });

    it("updates station gfx", function(){
      sinon.stub(station, '_set_orbit_angle'); /// stub out set_orbit_angle
      sinon.stub(station, 'update_gfx');
      station._run_orbit_movement();
      sinon.assert.called(station.update_gfx);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      station.init_gfx();

      var spies = [];
      for(var l = 0; l < station.lamps.olamps.length; l++)
        spies.push(sinon.spy(station.lamps.olamps[l], 'run_effects'))

      station.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("runs movement effects", function(){
      sinon.stub(station, '_run_movement_effects');
      station.run_effects();
      sinon.assert.called(station._run_movement_effects);
    });
  });
});});
