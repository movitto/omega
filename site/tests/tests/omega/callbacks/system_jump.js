pavlov.specify("Omega.CallbackHandler", function(){
describe("Omega.CallbackHandler", function(){
  describe("callbacks", function(){
    describe("#system_jump", function(){
      var page, tracker;
      var jumped, system, esystem, ejumped, estation, eargs, nsys, psys;

      before(function(){
        page = new Omega.Pages.Test();
        sinon.stub(page, 'process_entity');

        tracker = new Omega.CallbackHandler({page : page});

        system  = Omega.Gen.solar_system({id : 'sys1'});
        esystem = Omega.Gen.solar_system({id : 'sys1'});
        nsys    = Omega.Gen.solar_system({id : 'sys2'});
        psys    = Omega.Gen.solar_system({id : 'sys2'});

        jumped  = new Omega.Ship({id : 'sh1' });
        ejumped = new Omega.Ship({id : 'sh1',
                                  solar_system :  nsys,
                                  system_id : nsys.id});

        eargs = ['system_jump', ejumped, esystem];
      });

      it("updates entity system", function(){
        page.entities = [jumped, psys];
        tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
        assert(page.entity(jumped.id).solar_system).equals(psys);
      });

      describe("entity does not exist locally", function(){
        it("stores entity in registry", function(){
          page.entities = [psys];
          tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
          assert(page.entity(jumped.id)).isNotNull();
        });
      });

      describe("entity in scene root", function(){
        before(function(){
          page.canvas.set_scene_root(psys);
        });

        it("processes_entity on page", function(){
          page.entities = [jumped, psys];
          tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
          sinon.assert.calledWith(page.process_entity, jumped);
        });
      });
    });
  });
});});
