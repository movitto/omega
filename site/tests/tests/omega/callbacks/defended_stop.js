pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#defended_stop", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test();

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.CallbackHandler({page : page});

        tgt    = Omega.Gen.ship({id : 'target_ship', system_id : 'system1' });
        etgt   = Omega.Gen.ship({id : 'target_ship', hp : 77, shield_level : 99 });
        ship   = Omega.Gen.ship({id: 'ship1'});
        eship  = Omega.Gen.ship({id: 'ship1', attacking : etgt});

        tgt.init_gfx();
        ship.init_gfx();

        page.entities = [ship, tgt];
        page.canvas.entities = [tgt.id];
        eargs         = ['defended_stop', etgt, eship];
      });

      it("updates entity hp and shield level", function(){
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(77);
        assert(tgt.shield_level).equals(99);
      });

      it("updates entity defense gfx", function(){
        sinon.stub(tgt, 'update_defense_gfx');
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        sinon.assert.called(tgt.update_defense_gfx);
      });
    });
  });
});});
