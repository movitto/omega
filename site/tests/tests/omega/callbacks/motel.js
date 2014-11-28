pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#motel_event", function(){
      var page, tracker;
      var ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test();
        sinon.stub(page.audio_controls, 'play');
        sinon.stub(page.audio_controls, 'stop');

        tracker = new Omega.CallbackHandler({page: page});

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        ship  = Omega.Gen.ship({system_id : 'system1'});
        ship.location.id = 42;
        ship.location.set(0,0,0);
        ship.location.movement_strategy =
          {json_class : 'Motel::MovementStrategies::Stopped'};

        eship = ship.clone();
        eship.location = ship.location.clone();
        eship.location.set(1,1,1);
                                
        page.entity(ship.id, ship);
        eargs         = [eship.location];
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

      it("updates entity movement effects", function(){
        sinon.stub(ship, 'update_movement_effects');
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.assert.calledWith(ship.update_movement_effects);
      });

      it("updates entity gfx", function(){
        sinon.stub(ship, 'update_gfx');
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.assert.called(ship.update_gfx);
      });

      describe("entity was moving and now is stopped", function(){
        before(function(){
          ship.init_gfx();
          ship.location.movement_strategy.json_class =
            'Motel::MovementStrategies::Linear';
        });

        it("plays 'epic' audio effect", function(){
          tracker._callbacks_motel_event('motel::on_movement', eargs);
          sinon.assert.calledWith(page.audio_controls.play,
                                  page.audio_controls.effects.epic);
        });

        it("stops playing entity movement audio", function(){
          tracker._callbacks_motel_event('motel::on_movement', eargs);
          sinon.assert.calledWith(page.audio_controls.stop,
                                  ship.movement_audio);
        });
      });
    });
  });
});});
