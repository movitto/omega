pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#mining_stopped", function(){
      var page, tracker;
      var ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test();
        sinon.stub(page.canvas.entity_container, 'refresh_details');

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tracker = new Omega.CallbackHandler({page : page});

        var res = new Omega.Resource();
        var ast = new Omega.Asteroid();

        ship  = Omega.Generate.ship({id        : 'ship1',
                                     system_id : 'system1',
                                     mining    : ast});
        eship = Omega.Generate.ship({id: 'ship1'});


        page.entities = [ship];
        eargs         = ['mining_stopped', eship, res, 'cargo_full'];
      });

      it("clears entity mining target", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        assert(ship.mining).isNull();
      });

      it("clears entity mining asteroid", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        assert(ship.mining_asteroid).isNull();
      });

      it("updates entity gfx", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.stub(ship, 'update_mining_gfx');
        sinon.assert.called(ship.update_gfx);
      });

      it("refreshes entity container details", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh_details);
      });
    });
  });
});});
