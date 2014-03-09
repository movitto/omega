pavlov.specify("Omega.StationLamps", function(){
describe("Omega.StationLamps", function(){
  it("has a Omega.UI.CanavasLamp instance", function(){
    var type = 'manufacturing';
    var station_lamps = new Omega.StationLamps({config: Omega.Config, type: type});

    assert(station_lamps.olamps.length).
      equals(Omega.Config.resources.stations[type].lamps.length);

    for(var l = 0; l < station_lamps.length; l++){
      var lamp = station_lamps[l];
      assert(lamp).isOfType(Omega.UI.CanvasLamp);
    }
  });

  describe("#update", function(){
    var loc, lamps;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      lamps = new Omega.StationLamps({config: Omega.Config, type: 'manufacturing'});
      lamps.init_gfx();
      lamps.omega_entity = {location: loc};
    });

    after(function(){
      if(Omega.rotate_position.restore) Omega.rotate_position.restore();
    });

    it("sets & rotates lamps' position", function(){
      var rotate = sinon.spy(Omega, 'rotate_position');
      var rot_matrix = loc.rotation_matrix();
      lamps.update();

      var config_lamps = Omega.Config.resources.stations['manufacturing'].lamps;
      for(var l = 0; l < config_lamps.length; l++){
        var config_lamp = config_lamps[l];
        var lamp = lamps.olamps[l];
        assert(lamp.component.position.x).equals(loc.x + config_lamp[2][0]);
        assert(lamp.component.position.y).equals(loc.y + config_lamp[2][1]);
        assert(lamp.component.position.z).equals(loc.z + config_lamp[2][2]);
        sinon.assert.calledWith(rotate, lamp.component, rot_matrix);
      }
    });
  });
});}); // Omega.StationLamps
