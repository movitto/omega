pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#construction_failed", function(){
      var page, tracker;
      var failed, station, estation, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : new Omega.UI.Canvas()});
        sinon.stub(page.canvas.entity_container, 'refresh_details');
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas, 'animate');

        tracker = new Omega.CallbackHandler({page : page});

        var system = new Omega.SolarSystem({id : 'sys1'});
        page.canvas.set_scene_root(system);

        failed   = Omega.Gen.ship({id : 'failed_ship' });
        station  = Omega.Gen.station({id : 'station1', system_id : 'sys1', construction_percent: 0.4});
        estation = Omega.Gen.station({id : 'station1', system_id : 'sys1', resources : [{'material_id' : 'gold'}]});

        page.entities = [station, failed];
        eargs         = ['construction_failed', estation, failed];
      });

      after(function(){
        page.canvas.reload.restore();
        page.canvas.entity_container.refresh_details.restore();
        page.canvas.animate.restore();
      });

      it("sets station._constructing to false", function(){
        tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
        assert(station._construction).isFalse();
      });

      it("sets station construction percentage to 0", function(){
        tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
        assert(station.construction_percent).equals(0);
      });

      it("updates station resources", function(){
        sinon.spy(station, '_update_resources');
        tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
        sinon.assert.called(station._update_resources);
        assert(estation.resources).isSameAs(estation.resources)
      });

      describe("station system is scene root", function(){
        it("reloads station in scene", function(){
          tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
          sinon.assert.calledWith(page.canvas.reload, station, sinon.match.func);
        });

        it("updates construction graphics", function(){
          sinon.stub(station, 'update_construction_gfx');
          tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
          page.canvas.reload.omega_callback()(station);
          sinon.assert.called(station.update_construction_gfx);
        });

        it("animates scene", function(){
          sinon.stub(station, 'update_construction_gfx');
          tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
          page.canvas.reload.omega_callback()(station);
          sinon.assert.called(page.canvas.animate);
        });
      });

      it("refreshes the entity container details", function(){
        tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh_details);
      });
    });
  });
});});
