/// Test Mixin usage through Planet
pavlov.specify("Omega.PlanetGfxEffects", function(){
describe("Omega.PlanetGfxEffects", function(){
  describe("#run_effects", function(){
    var pl, loc;

    before(function(){
      loc = new Omega.Location({movement_strategy:
                                Omega.Gen.orbit_ms({e : 0, p : 10})});
      pl  = Omega.Gen.planet({location : loc});
      pl.location.set(10,0,0);
      pl.location.movement_strategy.dmajx = 0;
      pl.location.movement_strategy.dmajy = 0;
      pl.location.movement_strategy.dmajz = 1;
      pl.location.movement_strategy.dminx = 0;
      pl.location.movement_strategy.dminy = 1;
      pl.location.movement_strategy.dminz = 0;

      pl.init_gfx();
    });

    it("moves planet", function(){
      // XXX sinon-qunit enables fake timers by default
      this.clock.restore();

      pl.last_moved = new Date() - 1000;
      pl.run_effects();
      assert(pl.location.x).close(  0,2);
      assert(pl.location.y).close(  0,2);
      assert(pl.location.z).close(-10,2);
    });

    it("spins planet", function(){
      sinon.spy(pl.mesh, 'spin');
      pl.last_moved = new Date() - 1000;
      pl.run_effects();
      sinon.assert.calledWith(pl.mesh.spin, 0.5 * pl.spin_scale)
    });

    it("refreshes planet graphics", function(){
      var update_gfx = sinon.spy(pl, 'update_gfx');
      pl.last_moved = new Date();
      pl.run_effects();
      sinon.assert.called(update_gfx);
    });

    it("sets planet last movement time", function(){
      pl.last_moved = null;
      pl.run_effects();
      assert(pl.last_moved).isNotNull();
    });
  });
});});
