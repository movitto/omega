pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#mining_stopped", function(){
      var page, tracker;
      var ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas.entity_container, 'refresh');

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.UI.CommandTracker({page : page});

        var res = new Omega.Resource();
        var ast = new Omega.Asteroid();

        ship  = Omega.Generate.ship({id        : 'ship1',
                                     system_id : 'system1',
                                     mining    : ast});
        eship = Omega.Generate.ship({id: 'ship1'});


        page.entities = [ship];
        eargs         = ['mining_stopped', eship, res, 'cargo_full'];
      });

      after(function(){
        page.canvas.reload.restore();
        page.canvas.entity_container.refresh.restore();
      });

      it("clears entity mining target", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        assert(ship.mining).isNull();
      });

      it("clears entity mining asteroid", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        assert(ship.mining_asteroid).isNull();
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(page.canvas.reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.stub(ship, 'update_gfx');
        page.canvas.reload.omega_callback()();
        sinon.assert.called(ship.update_gfx);
      });

      it("refreshes entity container", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh);
      });
    });
  });
});});
