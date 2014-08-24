pavlov.specify("Omega.ShipTrails", function(){
describe("Omega.ShipTrails", function(){
  it("has a SPE Group instance", function(){
    var type = 'corvette';
    var conf = Omega.Config.resources.ships[type].trails;
    var trails = new Omega.ShipTrails({type: type});
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

      trails = new Omega.ShipTrails({type: 'corvette'});
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

  describe("#update_state", function(){
    var trails;

    before(function(){
      trails = new Omega.ShipTrails({type: 'corvette'});
      trails.omega_entity = Omega.Gen.ship();
    });

    describe("omega entity is stopped", function(){
      it("disables emitter", function(){
        sinon.stub(trails.omega_entity.location, 'is_stopped').returns(true);
        sinon.stub(trails, 'disable');
        trails.update_state();
        sinon.assert.called(trails.disable);
      });
    });

    describe("omega entity is not stopped", function(){
      it("enables emitter", function(){
        sinon.stub(trails.omega_entity.location, 'is_stopped').returns(false);
        sinon.stub(trails, 'enable');
        trails.update_state();
        sinon.assert.called(trails.enable);
      });
    });
  });
});}); // Omega.ShipTrails
