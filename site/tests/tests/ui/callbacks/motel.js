pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#motel_event", function(){
      var page, tracker;
      var ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas.entity_container, 'refresh');

        tracker = new Omega.UI.CommandTracker({page : page});

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        ship  = Omega.Gen.ship({system_id : 'system1'});
        ship.location.id = 42;
        ship.location.set(0,0,0);
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Stopped'};

        eship = ship.clone();
        eship.location.set(1,1,1);
                                
        page.entities = [ship];
        eargs         = [eship.location];
      });

      after(function(){
        page.canvas.reload.restore();
        page.canvas.entity_container.refresh.restore();
      });

      it("updates entity location", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        assert(ship.location.coordinates()).isSameAs(eship.location.coordinates());
      });

      it("sets entity.last_moved to now", function(){
        ship.last_moved = null;
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        assert(ship.last_moved).isSameAs(new Date());
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_motel_event('motel::on_movement', eargs);
          sinon.assert.notCalled(page.canvas.reload);
        });
      })

      it("reloads entity in scene", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.assert.calledWith(page.canvas.reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.stub(ship, 'update_gfx');
        page.canvas.reload.omega_callback()();
        sinon.assert.called(ship.update_gfx);
      });

      it("refreshes entity container", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.assert.called(page.canvas.entity_container.refresh);
      });
    });
  });
});});
