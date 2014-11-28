pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#partial_construction", function(){
      var page, tracker;
      var constructing, station, estation, eargs;

      before(function(){
        page = new Omega.Pages.Test();

        tracker = new Omega.CallbackHandler({page : page});

        var system = new Omega.SolarSystem({id : 'sys1'});
        page.canvas.set_scene_root(system);

        constructing = Omega.Gen.ship({id : 'constructing_ship' });
        station      = Omega.Gen.station({id : 'station1',
                                          system_id : 'sys1',
                                          construction_percent: 0.4});
        estation     = Omega.Gen.station({id : 'station1',
                                          system_id : 'sys1'});

        station.init_gfx();

        page.entity(station.id, station);
        page.entity(constructing.id, constructing);
        eargs         = ['partial_construction', estation, constructing, 0.6];
      });

      it("sets station._constructing to true", function(){
        tracker._callbacks_partial_construction("manufactured::event_occurred", eargs);
        assert(station._constructing).isTrue();
      });

      describe("station system is scene root", function(){
        it("sets station construction percentage", function(){
          tracker._callbacks_partial_construction("manufactured::event_occurred", eargs);
          assert(station.construction_percent).equals(0.6);
        })

        it("updates station construction graphics", function(){
          sinon.stub(station, 'update_construction_gfx');
          tracker._callbacks_partial_construction("manufactured::event_occurred", eargs);
          sinon.assert.called(station.update_construction_gfx);
        })
      });
    });
  });
});});
