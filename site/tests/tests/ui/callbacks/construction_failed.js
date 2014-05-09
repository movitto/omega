pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#construction_failed", function(){
      var page, tracker;
      var failed, station, estation, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas.entity_container, 'refresh_details');
        sinon.stub(page.canvas, 'reload');

        tracker = new Omega.UI.CommandTracker({page : page});

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

      it("reloads station in scene", function(){
        tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, station, sinon.match.func);
      });

      it("refreshes the entity container details", function(){
        tracker._callbacks_construction_failed("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh_details);
      });
    });
  });
});});
