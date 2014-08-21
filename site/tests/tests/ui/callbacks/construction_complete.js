pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#construction_complete", function(){
      var page, tracker;
      var constructed, station, estation, eargs;

      before(function(){
        sinon.stub(Omega.Ship, 'get');

        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page, 'process_entity');
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas.entity_container, 'refresh_details');
        sinon.stub(page.canvas, 'animate');

        page.audio_controls = new Omega.UI.AudioControls({page: page});
        page.audio_controls.disabled = true;

        tracker = new Omega.CallbackHandler({page : page});

        var system = new Omega.SolarSystem({id : 'sys1'});
        page.canvas.set_scene_root(system);

        constructed = Omega.Gen.ship({id : 'constructed_ship' });
        station     = Omega.Gen.station({id : 'station1',
                                         system_id : 'sys1',
                                         construction_percent: 0.4});
        estation    = Omega.Gen.station({id  : 'station1', 
                                         system_id : 'sys1',
                                         resources : [{'material_id' : 'gold'}]});

        page.entities = [station, constructed];
        eargs         = ['construction_complete', estation, constructed];
      });

      after(function(){
        Omega.Ship.get.restore();
        page.canvas.reload.restore();
        page.canvas.entity_container.refresh_details.restore();
        page.canvas.animate.restore();
      });

      it("sets station._constructing to false", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        assert(station._construction).isFalse();
      });

      it("sets station construction percent to 0", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        assert(station.construction_percent).equals(0);
      });

      it("updates station resources", function(){
        sinon.spy(station, '_update_resources');
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.called(station._update_resources);
        assert(estation.resources).isSameAs(estation.resources)
      });

      describe("station system is scene root", function(){
        it("reloads station in scene", function(){
          tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
          sinon.assert.calledWith(page.canvas.reload,
                                  station, sinon.match.func);
        });

        it("updates construction graphics", function(){
          sinon.stub(station, 'update_construction_gfx');
          tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
          page.canvas.reload.omega_callback()(station);
          sinon.assert.called(station.update_construction_gfx);
        });

        it("animates scene", function(){
          sinon.stub(station, 'update_construction_gfx'); /// stub out update_construction_gfx
          tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
          page.canvas.reload.omega_callback()(station);
          sinon.assert.called(page.canvas.animate);
        });
      });

      it("retrieves constructed entity", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(Omega.Ship.get,
          'constructed_ship', page.node, sinon.match.func);
      });

      it("processes constructed entity", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        var retrieved = new Omega.Ship();
        Omega.Ship.get.omega_callback()(retrieved);
        sinon.assert.calledWith(page.process_entity, retrieved);
      });

      it("plays construction complete audio effect", function(){
        sinon.stub(page.audio_controls, 'play');
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);

        var retrieved = new Omega.Ship({system_id : 'sys1'});
        station.construction_audio = 'audio';

        Omega.Ship.get.omega_callback()(retrieved);
        sinon.assert.calledWith(page.audio_controls.play,
                                station.construction_audio, 'complete');
      });

      it("refreshes the entity container details", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.called(page.canvas.entity_container.refresh_details);
      });
    });
  });
});});
