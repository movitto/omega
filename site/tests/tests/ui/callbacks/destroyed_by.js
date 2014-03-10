pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#destroyed_by", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test({canvas : Omega.Test.Canvas()});
        sinon.stub(page.canvas, 'reload');
        sinon.stub(page.canvas, 'remove');

        page.audio_controls = new Omega.UI.AudioControls({page: page});
        page.audio_controls.disabled = true;

        tracker = new Omega.UI.CommandTracker({page : page});

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tgt    = new Omega.Gen.ship({id : 'target_ship', system_id : 'system1' });
        etgt   = new Omega.Gen.ship({id : 'target_ship' });
        ship   = new Omega.Gen.ship({id : 'ship1', system_id : 'system1' });
        eship  = new Omega.Gen.ship({id : 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        page.canvas.entities = [ship.id, tgt.id];
        eargs         = ['destroyed_by', etgt, eship];
      });

      after(function(){
        page.canvas.reload.restore();
        page.canvas.remove.restore();
      });

      it("clears entity attacking target", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        assert(ship.attacking).isNull();
      });

      it("sets entity hp and shield level to 0", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(0);
        assert(tgt.shield_level).equals(0);
      });

      it("reloads attacker in scene", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(page.canvas.reload, ship, sinon.match.func);
      });

      it("updates attacker gfx", function(){
        sinon.stub(ship, 'update_gfx');
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        page.canvas.reload.omega_callback()();
        sinon.assert.called(ship.update_gfx);
      });

      it("triggers defender destruction", function(){
        sinon.stub(tgt, 'trigger_destruction');
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(tgt.trigger_destruction, sinon.match.func);
      });

      describe("on defender destruction", function(){
        var trigger_cb;

        before(function(){
          sinon.stub(tgt, 'trigger_destruction');
          tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
          trigger_cb = tgt.trigger_destruction.omega_callback();
        });

        it("updates defender gfx", function(){
          sinon.stub(tgt, 'update_gfx');
          trigger_cb();
          sinon.assert.called(tgt.update_gfx);
        });

        it("removes defender from scene", function(){
          trigger_cb();
          sinon.assert.calledWith(page.canvas.remove, tgt);
        });
      });
    });
  });
});});
