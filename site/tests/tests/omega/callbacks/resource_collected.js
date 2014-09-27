pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#resource_collected", function(){
      var page, tracker;
      var ship, eship, eargs, ares, ast;

      before(function(){
        page = new Omega.Pages.Test();
        sinon.stub(page.canvas.entity_container, 'refresh_details');

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.CallbackHandler({page : page});

        var res  = new Omega.Resource({material_id : 'gold', quantity : 10});
        var eres = new Omega.Resource({id : 'res1', material_id : 'gold', quantity : 50});

        ares = new Omega.Resource({id : 'res1', material_id : 'gold', quantity : 50});
        ast  = new Omega.Asteroid();
        ast.resources   = [ares];
        system.children = [ast];

        ship  = Omega.Gen.ship({id        : 'ship1',
                                system_id : 'system1',
                                resources : [res]});
        ship.init_gfx();

        eship = Omega.Gen.ship({id        : 'ship1',
                                resources : [eres],
                                mining    :  eres});
        page.entities = [ship, system];
        eargs         = ['resource_collected', eship, res, 40];
      });

      it("updates entity mining target", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        assert(ship.mining).equals(ares);
        assert(ship.mining_asteroid).equals(ast);
      });

      it("updates entity resources", function(){
        sinon.spy(ship, '_update_resources');
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        assert(ship.resources).isSameAs(eship.resources);
        sinon.assert.called(ship._update_resources);
      });

      it("updates entity mining gfx", function(){
        sinon.stub(ship, 'update_mining_gfx');
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        sinon.assert.called(ship.update_mining_gfx);
      });

      it("refreshes entity container details", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh_details);
      });
    });
  });
});});
