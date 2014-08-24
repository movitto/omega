// Test mixin usage through ship
pavlov.specify("Omega.ShipGfxEffects", function(){
describe("Omega.ShipGfxEffects", function(){
  var ship;

  before(function(){
    ship = Omega.Gen.ship();
  });

  describe("#run_effects", function(){
    var ship;

    before(function(){
      ship = Omega.Gen.ship();
      ship.init_gfx();
    });

    it("runs movement", function(){
      sinon.spy(ship, '_run_movement');
      ship.run_effects();
      sinon.assert.called(ship._run_movement);
    });

    it("runs lamp effects", function(){
      sinon.spy(ship.lamps, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.lamps.run_effects);
    });

    it("runs trail effects", function(){
      sinon.spy(ship.trails, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.trails.run_effects);
    });

    it("runs visited route effects", function(){
      sinon.spy(ship.visited_route, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.visited_route.run_effects);
    });

    it("runs attack component effects", function(){
      sinon.spy(ship.attack_component(), 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.attack_component().run_effects);
    });

    it("runs mining vector effects", function(){
      sinon.spy(ship.mining_vector, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.mining_vector.run_effects);
    });

    it("runs destruction effects", function(){
      sinon.spy(ship.destruction, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.destruction.run_effects);
    });

    it("runs smoke effects", function(){
      sinon.spy(ship.smoke, 'run_effects');
      ship.run_effects();
      sinon.assert.called(ship.smoke.run_effects);
    });
  });

  describe("#update_gfx", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({type : 'corvette', location : new Omega.Location()});
      ship.init_gfx();
    });

    it("sets position tracker position from scene location", function(){
      sinon.spy(ship.position_tracker().position, 'set');
      ship.update_gfx();
      sinon.assert.calledWith(ship.position_tracker().position.set,
                              ship.location.x,
                              ship.location.y,
                              ship.location.z);
    });

    it("sets location tracker rotation from location rotation", function(){
      var matrix = new THREE.Matrix4();
      sinon.stub(ship.location, 'rotation_matrix').returns(matrix);
      sinon.spy(ship.location_tracker().rotation, 'setFromRotationMatrix');
      ship.update_gfx();
      sinon.assert.calledWith(ship.location_tracker().rotation.setFromRotationMatrix, matrix);
    });

    it("updates attack component", function(){
      sinon.stub(ship.attack_component(), 'update');
      ship.update_gfx();
      sinon.assert.called(ship.attack_component().update);
    });

    it("updates attack & mining vectors", function(){
      var update_attack = sinon.spy(ship.attack_vector, 'update');
      var update_mining = sinon.spy(ship.mining_vector, 'update');
      ship.update_gfx();
      sinon.assert.called(update_attack);
      sinon.assert.called(update_mining);
    });
  });
});});
