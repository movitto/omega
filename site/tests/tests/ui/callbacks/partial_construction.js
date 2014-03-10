pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#partial_construction", function(){
      var page, tracker;
      var constructing, station, estation, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas, 'reload');

        tracker = new Omega.UI.CommandTracker({page : page});

        constructing = Omega.Gen.ship({id : 'constructing_ship' });
        station      = Omega.Gen.station({id : 'station1',
                                          system_id : 'sys1',
                                          construction_percent: 0.4});
        estation     = Omega.Gen.station({id : 'station1',
                                          system_id : 'sys1'});
        page.entities = [station, constructing];
        eargs         = ['partial_construction', estation, constructing, 0.6];
      });

      after(function(){
        page.canvas.reload.restore();
      });

      it("sets station construction percentage", function(){
        tracker._callbacks_partial_construction("manufactured::event_occurred", eargs);
        assert(station.construction_percent).equals(0.6);
      })

      it("reloads station in scene", function(){
        tracker._callbacks_partial_construction("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, station, sinon.match.func);
      });
    });
  });
});});
