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
});});
