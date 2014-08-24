pavlov.specify("Omega.ShipHpBar", function(){
describe("Omega.ShipHpBar", function(){
  describe("#_update_hp_bar", function(){
    var loc, hp_bar;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      hp_bar = new Omega.ShipHpBar();
      hp_bar.init_gfx();
      hp_bar.omega_entity = {location: loc, hp : 10.0, max_hp : 100.0};
    });

    it("updates hp progress bar", function(){
      var update = sinon.spy(hp_bar.bar, 'update');
      hp_bar.update();
      sinon.assert.calledWith(update, 0.1);
    });
  });
});}); // Omega.ShipTrajectory

