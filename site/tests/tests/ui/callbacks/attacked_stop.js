pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#attacked_stop", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : new Omega.UI.Canvas()});
        sinon.stub(page.canvas, 'reload');

        tracker = new Omega.CallbackHandler({page : page});

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tgt    = Omega.Gen.ship({id : 'target_ship' });
        etgt   = Omega.Gen.ship({id : 'target_ship' });
        ship   = Omega.Gen.ship({id: 'ship1', system_id : 'system1'});
        eship  = Omega.Gen.ship({id: 'ship1', attacking : etgt});

        ship.init_gfx();

        page.entities = [ship, tgt];
        eargs         = ['attacked_stop', eship, etgt];
      });

      it("clears entity attacking target", function(){
        tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
        assert(ship.attacking).isNull();
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(page.canvas.reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, ship, sinon.match.func);
      });

      it("updates entity attack gfx", function(){
        sinon.stub(ship, 'update_attack_gfx');
        tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
        page.canvas.reload.omega_callback()();
        sinon.assert.called(ship.update_attack_gfx);
      });
    });
  });
});});
