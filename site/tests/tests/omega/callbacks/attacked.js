pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#attacked", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test();

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.CallbackHandler({page : page});

        tgt    = Omega.Gen.ship({id : 'target_ship' });
        etgt   = Omega.Gen.ship({id : 'target_ship' });
        ship   = Omega.Gen.ship({id: 'ship1', system_id : 'system1'});
        eship  = Omega.Gen.ship({id: 'ship1', attacking : etgt});

        ship.init_gfx();

        page.entities = [ship, tgt];
        eargs         = ['attacked', eship, etgt];
      });

      it("updates entity attacking target", function(){
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        assert(ship.attacking).equals(tgt);
      });

      it("updates entity attack gfx", function(){
        sinon.stub(ship, 'update_attack_gfx');
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        sinon.assert.called(ship.update_attack_gfx);
      });
    });
  });
});});
