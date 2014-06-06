pavlov.specify("Omega.ShipTrails", function(){
describe("Omega.ShipTrails", function(){
  it("has a SPE Group instance", function(){
    var type = 'corvette';
    var conf = Omega.Config.resources.ships[type].trails;
    var trails = new Omega.ShipTrails({config: Omega.Config, type: type});
    assert(trails.particles).isOfType(SPE.Group);
    assert(trails.particles.emitters.length).equals(conf.length);
  });

  describe("#update", function(){
    var loc, trails;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      trails = new Omega.ShipTrails({config: Omega.Config, type: 'corvette'});
      trails.omega_entity = {location: loc};
    });

    after(function(){
      if(Omega.set_rotation.restore) Omega.set_rotation.restore();
      if(Omega.rotate_position.restore) Omega.rotate_position.restore();
    });

    //it("sets trail positions, orientation, and velocity", function(){ /// NIY
    //  var set_rotation = sinon.spy(Omega, 'set_rotation');
    //  var rotate_position = sinon.spy(Omega, 'rotate_position');
    //  var rot_matrix = loc.rotation_matrix();
    //  trails.update();
    //});
  });
});}); // Omega.ShipTrails
