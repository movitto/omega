pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#resource_collected", function(){
      var page, tracker;
      var ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test();
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas.entity_container, 'refresh_details');

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.CallbackHandler({page : page});

        var res  = new Omega.Resource({material_id : 'gold', quantity : 10});
        var eres = new Omega.Resource({material_id : 'gold', quantity : 50});
        var ast  = new Omega.Asteroid();

        ship  = Omega.Gen.ship({id        : 'ship1',
                                system_id : 'system1',
                                resources : [res]});
        ship.init_gfx();

        eship = Omega.Gen.ship({id        : 'ship1',
                                resources : [eres],
                                mining    : ast});
        page.entities = [ship];
        eargs         = ['resource_collected', eship, res, 40];
      });

      it("updates entity mining target", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        assert(ship.mining).equals(eship.mining);
      });

      it("updates entity resources", function(){
        sinon.spy(ship, '_update_resources');
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        assert(ship.resources).isSameAs(eship.resources);
        sinon.assert.called(ship._update_resources);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(page.canvas.reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, ship, sinon.match.func);
      });

      it("updates entity mining gfx", function(){
        sinon.stub(ship, 'update_mining_gfx');
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        page.canvas.reload.omega_callback()();
        sinon.assert.called(ship.update_mining_gfx);
      });

      it("refreshes entity container details", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh_details);
      });
    });
  });
});});
