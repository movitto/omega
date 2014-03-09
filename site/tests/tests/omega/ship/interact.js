// Test mixin usage through ship
pavlov.specify("Omega.ShipInteraction", function(){
describe("Omega.ShipInteraction", function(){
  describe("#context_action", function(){
    var move_objects;

    before(function(){
      move_objects = [
        new Omega.Ship({id : 'ship2', system_id : 'sys1',
             location  : new Omega.Location({x:12,y:53,z:16})}),
        new Omega.Planet({id : 'planet_1', system_id : 'sys1',
             location  : new Omega.Location({x:16,y:35,z:76})}),
        new Omega.Asteroid({id : 'ast1',
             location  : new Omega.Location({x:25,y:30,z:66})}),
        new Omega.JumpGate({id : 'jg1',
             location  : new Omega.Location({x:-14,y:6,z:-8})}),
        new Omega.Station({id : 'st1',
             location  : new Omega.Location({x:-5,y:3,z:-86})})
      ];

      page.canvas.root = new Omega.SolarSystem({id : 'sys1',
                           children : move_objects});
    });

    //it("invokes move command on ships/stations/asteroids/planets/jump_gates", function(){ /// NIY
    //  var offset = Omega.Config.movement_offset;
    //  var move   = sinon.spy(ship, '_move');

    //  move_objects.forEach(function(entity){
    //    ship.context_action(entity, page);
    //    sinon.assert.calledWith(move, page);

    //    var move_args = move.lastCall.args;
    //    var validate = [move_args[1] - entity.location.x,
    //                    move_args[2] - entity.location.y,
    //                    move_args[3] - entity.location.z];
    //    validate.forEach(function(dist){
    //      assert(dist).isLessThan(offset.max);
    //      assert(dist).isGreaterThan(offset.min);
    //    });
    //  });
    //});

    describe("ship does not belong to user", function(){
      it("does not invoke move command", function(){
        var move   = sinon.spy(ship, '_move');
        ship.user_id = 'foouser';

        move_objects.forEach(function(entity){
          ship.context_action(entity, page);
        });
        sinon.assert.notCalled(move);
      });
    });

    after(function(){
      page.canvas.root = null;
    });
  });

  describe("#_select_destination", function(){
    var st, sh1, sh2, ast1, jg1, jg2;

    before(function(){
      ship.system_id = 'sys1';
      st   = new Omega.Station({id : 'station1', system_id : 'sys1'});
      sh1  = new Omega.Ship({id : ship.id, system_id : 'sys1'});
      sh2  = new Omega.Ship({id : 'ship2', system_id : 'sys1'});
      ast1 = new Omega.Asteroid({id : 'ast1'});
      jg1  = new Omega.JumpGate({id : 'jg1'});
      jg2  = new Omega.JumpGate({id : 'jg2'});

      page.canvas.root = new Omega.SolarSystem({id : 'sys1',
                           children : [ast1, jg1, jg2]});
      page.entity(st.id, st);
      page.entity(sh1.id, sh1);
      page.entity(sh2.id, sh2);
    });

    after(function(){
      page.canvas.root = null;
    });

    it("shows select destination dialog", function(){
      var show_dialog = sinon.spy(ship.dialog(), 'show_destination_selection_dialog');
      ship._select_destination(page);
      sinon.assert.calledWith(show_dialog, page, ship, sinon.match.object);
    });

    it("retrieves entities to render in destination select box", function(){
      var show_dialog = sinon.spy(ship.dialog(), 'show_destination_selection_dialog');
      ship._select_destination(page);

      var entities = show_dialog.getCall(0).args[2];
      assert(entities['stations']).isSameAs([st]);
      assert(entities['ships']).isSameAs([sh2]);
      assert(entities['asteroids']).isSameAs([ast1]);
      assert(entities['jump_gates']).isSameAs([jg1,jg2]);
    });
  });

  describe("#_move", function(){
    it("invokes manufactured::move_entity with updated location", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._move(page, 100, 200, -50);
      sinon.assert.calledWith(http_invoke,
        'manufactured::move_entity', ship.id,
        sinon.match.ofType(Omega.Location),
        sinon.match.func);
      var loc = http_invoke.getCall(0).args[2];
      assert(loc).isNotEqualTo(ship.loc);
      assert(loc.x).equals(100);
      assert(loc.y).equals(200);
      assert(loc.z).equals(-50);
    });

    describe("on manufactured::move_entity response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._move(page, 100, 200, -50);
        response_cb = http_invoke.getCall(0).args[3];

        var sloc = new Omega.Location({movement_strategy :
          {json_class : 'Motel::MovementStrategies::Rotate'}});
        nship = new Omega.Ship({location : sloc});
        success_response = {result : nship};
        error_response   = {error  : {message : 'move err'}};
      });

      describe("error response", function(){
        it("clears error dialog", function(){
          var clear = sinon.spy(ship.dialog(), 'clear_errors');
          response_cb(error_response);
          sinon.assert.called(clear);
        });

        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Movement Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'move err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        })

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship movement strategy", function(){
          response_cb(success_response);
          assert(ship.location.movement_strategy).equals(nship.location.movement_strategy);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#select_attack_target", function(){
    it("shows attack dialog w/ all non-user-owned ships in vicinity that are alive", function(){
      var ship1 = new Omega.Ship({user_id : 'user1', hp : 100, location:
                    new Omega.Location({x:101,y:0,z:101})});
      var ship2 = new Omega.Ship({user_id : 'user2', hp : 100, location:
                    new Omega.Location({x:100,y:0,z:100})});
      var ship3 = new Omega.Ship({user_id : 'user2', hp : 100, location:
                    new Omega.Location({x:105,y:5,z:105})});
      var ship4 = new Omega.Ship({user_id : 'user2', hp : 100, location:
                    new Omega.Location({x:1000,y:1000,z:1000})});
      var ship5 = new Omega.Ship({user_id : 'user2', hp : 0, location:
                    new Omega.Location({x:106,y:6,z:106})});
      var station1 = new Omega.Station();
      page.entities = [ship1, ship2, ship3, ship4, ship5, station1];
      page.session = new Omega.Session({user_id : 'user1'});

      var show_dialog = sinon.spy(ship.dialog(), 'show_attack_dialog');
      ship._select_attack_target(page);
      sinon.assert.calledWith(show_dialog, page, ship, [ship2, ship3]);
    });
  });

  describe("#_start_attacking", function(){
    var tgt, evnt;

    before(function(){
      tgt = new Omega.Ship({id : 'tgt'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('target', tgt);
    });

    it("invokes manufactured::attack_entity with command target", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._start_attacking(page, evnt);
      sinon.assert.calledWith(http_invoke,
        'manufactured::attack_entity', ship.id,
        tgt.id, sinon.match.func);
    });

    describe("on manufactured::attack_entity response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._start_attacking(page, evnt);
        response_cb = http_invoke.getCall(0).args[3];

        nship = new Omega.Ship({attacking : tgt});
        success_response = {result : nship};
        error_response   = {error  : {message : 'attack err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Attack Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'attack err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        })

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship attack target", function(){
          response_cb(success_response);
          assert(ship.attacking).equals(tgt);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });

  describe("#_select_docking_station", function(){
    it("shows docking dialog w/ all user-owned stations in vicinity of ship", function(){
      var ship1     = new Omega.Ship();
      var station1  = new Omega.Station({user_id : 'user1', docking_distance : 100,
                                         location : new Omega.Location({x:100,y:0,z:100})});
      var station2  = new Omega.Station({user_id : 'user1', docking_distance : 100,
                                         location : new Omega.Location({x:105,y:5,z:105})});
      var station3  = new Omega.Station({user_id : 'user2', docking_distance: 100});
      var station4  = new Omega.Station({user_id : 'user1', docking_distance : 100,
                                         location : new Omega.Location({x:1000,y:1000,z:1000})});
      page.entities = [ship1, station1, station2, station3, station4];
      page.session  = new Omega.Session({user_id : 'user1'});

      var show_dialog = sinon.spy(ship.dialog(), 'show_docking_dialog');
      ship._select_docking_station(page);
      sinon.assert.calledWith(show_dialog, page, ship, [station1, station2]);
    });
  });

  describe("#_dock", function(){
    var station, evnt;

    before(function(){
      station = new Omega.Station({id : 'station1'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('station', station);
    });

    it("invokes manufacured::dock with command station", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._dock(page, evnt);
      sinon.assert.calledWith(http_invoke,
        'manufactured::dock', ship.id, station.id,
        sinon.match.func);
    });

    describe("on manufactured::dock response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._dock(page, evnt);
        response_cb = http_invoke.getCall(0).args[3];

        nship = new Omega.Ship({docked_at : station});
        success_response = {result : nship};
        error_response   = {error  : {message : 'dock err'}};
      });

      describe("manufactured::dock error", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Docking Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'dock err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
          if(page.canvas.entity_container.refresh.restore)
            page.canvas.entity_container.refresh.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship docked at entity", function(){
          response_cb(success_response);
          assert(ship.docked_at).equals(station);
        });

        it("updates ship docked at id", function(){
          response_cb(success_response);
          assert(ship.docked_at_id).equals(station.id);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });

        it("refreshes entity container", function(){
          var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
          response_cb(success_response);
          sinon.assert.called(refresh);
        });
      });
    });
  });

  describe("#_undock", function(){
    before(function(){
      ship.docked_at = new Omega.Station();
    });

    it("invokes manufactured::undock", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._undock(page);
      sinon.assert.calledWith(http_invoke,
        'manufactured::undock', ship.id,
        sinon.match.func);
    });

    describe("on manufactured::undock response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._undock(page);
        response_cb = http_invoke.getCall(0).args[2];

        nship = new Omega.Ship({});
        success_response = {result : nship};
        error_response   = {error  : {message : 'undock err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Undocking Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'undock err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
          if(page.canvas.entity_container.refresh.restore)
            page.canvas.entity_container.refresh.restore();
        });

        it("clears ship docked_at entity", function(){
          response_cb(success_response);
          assert(ship.docked_at).isNull();
        });

        it("clears ship docked_at_id", function(){
          response_cb(success_response);
          assert(ship.docked_at_id).isNull();
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });

        it("refreshes entity container", function(){
          var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
          response_cb(success_response);
          sinon.assert.called(refresh);
        });
      });
    });
  });

  describe("#_transfer", function(){
    before(function(){
      ship.docked_at_id = 'station1';

      var res1 = new Omega.Resource();
      var res2 = new Omega.Resource();
      ship.resources = [res1, res2];
    });

    it("invokes manufactured::transfer_resource with all ship resources", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._transfer(page);
      sinon.assert.calledWith(http_invoke,
        'manufactured::transfer_resource', ship.id,
        ship.docked_at_id, ship.resources[0],
        sinon.match.func);
      sinon.assert.calledWith(http_invoke,
        'manufactured::transfer_resource', ship.id,
        ship.docked_at_id, ship.resources[1],
        sinon.match.func);
    });

    describe("on manufactured::transfer_resource response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        station = new Omega.Station();
        nstation = new Omega.Station({resources : [{data : {material_id : 'silver'}}]});

        ship.docked_at = station;
        ship._transfer(page);
        response_cb = http_invoke.getCall(0).args[4];

        nship = new Omega.Ship({docked_at : nstation,
                                resources : [new Omega.Resource()]});
        success_response = {result : [nship, nstation]};
        error_response   = {error  : {message : 'transfer err'}};
      });

      describe("error response", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Transfer Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'transfer err');
        });
      });

      describe("successful response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
          if(page.canvas.entity_container.refresh.restore)
            page.canvas.entity_container.refresh.restore();
        });

        it("updates ship resources", function(){
          response_cb(success_response);
          assert(ship.resources).equals(nship.resources);
        });

        it("updates station resources", function(){
          response_cb(success_response);
          assert(station.resources.length).equals(1);
          assert(station.resources[0].material_id).equals('silver');
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });

        it("refreshes entity container", function(){
          var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
          response_cb(success_response);
          sinon.assert.called(refresh);
        });
      });
    });
  });

  describe("#_select_mining_target", function(){
    var ast1, ast2, ast3;
    before(function(){
      ast1 = new Omega.Asteroid({id : 'ast1', location : new Omega.Location({x:100,y:0,z:100})})
      ast2 = new Omega.Asteroid({id : 'ast2', location : new Omega.Location({x:101,y:1,z:101})});
      ast3 = new Omega.Asteroid({id : 'ast3', location : new Omega.Location({x:1000,y:1000,z:1000})});
      var asts = [ast1, ast2, ast3];
      ship.solar_system = new Omega.SolarSystem({children: asts});
    });

    it("shows mining dialog", function(){
      var show_dialog = sinon.spy(ship.dialog(), 'show_mining_dialog');
      ship._select_mining_target(page);
      sinon.assert.calledWith(show_dialog, page, ship);
    });

    it("invokes cosmos::get_resources with each asteroid in vicinity of ship", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._select_mining_target(page);
      sinon.assert.calledWith(http_invoke, 'cosmos::get_resources', ast1.id);
      sinon.assert.calledWith(http_invoke, 'cosmos::get_resources', ast2.id);
    });

    describe("successfull cosmos::get_resources response", function(){
      var resources, response, response_cb;
      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._select_mining_target(page);
        response_cb = http_invoke.getCall(0).args[2];

        resources = [new Omega.Resource(), new Omega.Resource()];
        response = {result : resources};
      });

      it("appends mining command for resources to dialog", function(){
        var append_cmd = sinon.spy(ship.dialog(), 'append_mining_cmd');
        response_cb(response);
        sinon.assert.calledWith(append_cmd, page, ship, resources[0]);
        sinon.assert.calledWith(append_cmd, page, ship, resources[1]);
      });
    });
  });

  describe("_start_mining", function(){
    var resource, evnt;

    before(function(){
      resource = new Omega.Resource({id : 'res1'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('resource', resource);
    });

    it("invokes manufactured::start_mining with command resource", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      ship._start_mining(page, evnt);
      sinon.assert.calledWith(http_invoke,
        'manufactured::start_mining', ship.id, resource.id,
        sinon.match.func);
    });

    describe("on manufactured::start_mining response", function(){
      var response_cb, nship,
          success_response, error_response;

      before(function(){
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        ship._start_mining(page, evnt);
        response_cb = http_invoke.getCall(0).args[3];

        nship = new Omega.Ship({mining: resource});
        success_response = {result : nship};
        error_response   = {error  : {message : 'mining err'}};
      });

      describe("manufactured::start_mining error", function(){
        it("shows error dialog", function(){
          var show = sinon.spy(ship.dialog(), 'show_error_dialog');
          response_cb(error_response);
          sinon.assert.called(show);
        });

        it("sets dialog title", function(){
          response_cb(error_response);
          assert(ship.dialog().title).equals('Mining Error');
        });

        it("appends error to dialog", function(){
          var append = sinon.spy(ship.dialog(), 'append_error');
          response_cb(error_response);
          sinon.assert.calledWith(append, 'mining err');
        });
      });

      describe("successful manufactured::start_mining response", function(){
        var reload;

        before(function(){
          reload = sinon.stub(page.canvas, 'reload');
        });

        after(function(){
          page.canvas.reload.restore();
        });

        it("hides the dialog", function(){
          var hide = sinon.spy(ship.dialog(), 'hide');
          response_cb(success_response);
          sinon.assert.called(hide);
        });

        it("updates ship mining target", function(){
          response_cb(success_response);
          assert(ship.mining).equals(nship.mining);
        });

        it("reloads ship in canvas scene", function(){
          response_cb(success_response);
          sinon.assert.calledWith(reload, ship);
        });

        it("updates ship graphics", function(){
          response_cb(success_response);
          var reload_cb = reload.getCall(0).args[1];

          var update_gfx = sinon.spy(ship, 'update_gfx');
          reload_cb();
          sinon.assert.called(update_gfx);
        });
      });
    });
  });
});});
