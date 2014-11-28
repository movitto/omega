pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#destroyed_by", function(){
      var page, tracker;
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        page = new Omega.Pages.Test();
        sinon.stub(page.canvas, 'remove');

        tracker = new Omega.CallbackHandler({page : page});

        var system = new Omega.SolarSystem({id : 'system1'});
        page.canvas.set_scene_root(system);

        tgt    = new Omega.Gen.ship({id : 'target_ship', system_id : 'system1' });
        etgt   = new Omega.Gen.ship({id : 'target_ship' });
        ship   = new Omega.Gen.ship({id : 'ship1', system_id : 'system1' });
        eship  = new Omega.Gen.ship({id : 'ship1', attacking : etgt});

        tgt.init_gfx()
        ship.init_gfx()

        page.entity(ship.id, ship);
        page.entity(tgt.id, tgt);
        page.canvas.entities = [ship.id, tgt.id];
        eargs         = ['destroyed_by', etgt, eship];
      });

      it("clears entity attacking target", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        assert(ship.attacking).isUndefined();
      });

      it("sets entity hp and shield level to 0", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(0);
        assert(tgt.shield_level).equals(0);
      });

      it("updates attacker attack gfx", function(){
        sinon.stub(ship, 'update_attack_gfx');
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.called(ship.update_attack_gfx);
      });

      it("updates defender defense gfx", function(){
        sinon.stub(tgt, 'update_defense_gfx');
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.called(tgt.update_defense_gfx);
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

        it("removes defender from scene", function(){
          trigger_cb();
          sinon.assert.calledWith(page.canvas.remove, tgt);
        });
      });
    });
  });
});});
