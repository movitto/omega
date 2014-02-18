pavlov.specify("Omega.Ship", function(){
describe("Omega.Ship", function(){
  var ship, page;

  before(function(){
    ship = new Omega.Ship({id : 'ship1', user_id : 'user1',
                    hp : 42,
                    attack_distance : 100,
                    mining_distance : 100,
                    location  : new Omega.Location({x:99,y:-2,z:100,
                                                    orientation_x:0,
                                                    orientation_y:0,
                                                    orientation_z:1}),
                    resources : [{quantity : 50, material_id : 'gold'},
                                 {quantity : 25, material_id : 'ruby'}]});
    page = new Omega.Pages.Test({canvas: Omega.Test.Canvas(),
                                 node: new Omega.Node(),
                                 session: new Omega.Session({user_id : 'user1'})});
  });

  it("sets parent_id = to system_id", function(){
    var ship = new Omega.Ship({system_id : 'system1'});
    assert(ship.parent_id).equals('system1');
  });

  it("converts location", function(){
    var ship = new Omega.Ship({location : {json_class: 'Motel::Location', y : -42}});
    assert(ship.location).isOfType(Omega.Location);
    assert(ship.location.y).equals(-42);
  });

  //it("updates resources"); /// NIY test update_resources is invoked

  describe("#belongs_to_user", function(){
    it("returns bool indicating if ship belongs to user", function(){
      assert(ship.belongs_to_user('user1')).isTrue();
      assert(ship.belongs_to_user('user2')).isFalse();
    });
  });

  describe("#alive", function(){
    describe("ship hp > 0", function(){
      it("returns true", function(){
        var ship = new Omega.Ship({hp:42});
        assert(ship.alive()).isTrue();
      });
    });

    describe("ship hp == 0", function(){
      it("returns false", function(){
        var ship = new Omega.Ship({hp:0});
        assert(ship.alive()).isFalse();
      });
    });
  });

  describe("update_system", function(){
    it("sets solar_system", function(){
      var sh = new Omega.Ship();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
      assert(sh.solar_system).equals(sys);
    });

    it("sets system_id", function(){
      var sh = new Omega.Ship();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
      assert(sh.system_id).equals(sys.id);
    });

    it("sets parent_id", function(){
      var sh = new Omega.Ship();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
      assert(sh.parent_id).equals(sys.id);
    });
  });

  describe("#in_system", function(){
    var sh, sys;
    before(function(){
      sh  = new Omega.Ship();
      sys = new Omega.SolarSystem({id : 'sys1'});
      sh.update_system(sys);
    });

    describe("ship is in system", function(){
      it("returns true", function(){
        assert(sh.in_system(sys.id)).isTrue();
      });
    });

    describe("ship is not in system", function(){
      it("returns false", function(){
        assert(sh.in_system('foobar')).isFalse();
      });
    });
  });

  describe("#_update_resources", function(){
    it("converts resources from json data", function(){
      var ship = new Omega.Ship({resources : [{data : {material_id : 'steel'}},
                                              {data : {material_id : 'plastic'}}]});
      assert(ship.resources.length).equals(2);
      assert(ship.resources[0].material_id).equals('steel');
      assert(ship.resources[1].material_id).equals('plastic');
    });
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
    });

    it("invokes details cb with ship id, location, and resources", function(){
      var text = ['Ship: ship1<br/>',
                  '@ 99/-2/100<br/>',
                  '> 0/0/1<br/>'          ,
                  'HP: 42<br/>'           ,
                  'Resources:<br/>'       ,
                  '50 of gold<br/>'       ,
                  '25 of ruby<br/>'      ];

      ship.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0]).equals(text[0]);
      assert(details[1]).equals(text[1]);
      assert(details[2]).equals(text[2]);
      assert(details[3]).equals(text[3]);
      assert(details[4]).equals(text[4]);
      assert(details[5]).equals(text[5]);
      assert(details[6]).equals(text[6]);
    });

    it("invokes details with commands", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var cmd = Omega.Ship.prototype.cmds[c];
        var detail_cmd = details[7+c];
        assert(detail_cmd[0].id).equals(cmd.id + ship.id);
        assert(detail_cmd[0].className).equals(cmd.class);
        assert(detail_cmd.html()).equals(cmd.text);
      }
    });

    describe("ship does not belong to user", function(){
      it("does not invoke details with commands", function(){
        ship.user_id = 'user2';
        ship.retrieve_details(page, details_cb);
        var details = details_cb.getCall(0).args[0];
        assert(details.length).equals(7);
      });
    });

    it("hides commands 'display' returns false for", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var cmd = Omega.Ship.prototype.cmds[c];
        var detail_cmd = details[7+c];
        var display = (!cmd.display || cmd.display(ship)) ? 'block' : 'none';
        assert(detail_cmd.css('display')).equals(display);
      }
    });

    describe("ship is not docked", function(){
      before(function(){
        ship.retrieve_details(page, function(details){
          $('#qunit-fixture').append(details);
        });
      });

      it("displays dock cmd", function(){
        assert($('#ship_dock_' + ship.id)).isVisible();
      });

      it("hides undock cmd", function(){
        assert($('#ship_undock_' + ship.id)).isHidden();
      });

      it("hides transfer cmd", function(){
        assert($('#ship_transfer_' + ship.id)).isHidden();
      });
    });

    describe("ship is docked", function(){
      before(function(){
        ship.docked_at_id = 'station1';
        ship.retrieve_details(page, function(details){
          $('#qunit-fixture').append(details);
        });
      });

      it("hides dock cmd", function(){
        assert($('#ship_dock_' + ship.id)).isHidden();
      });

      it("displays undock cmd", function(){
        assert($('#ship_undock_' + ship.id)).isVisible();
      });

      it("displays transfer cmd", function(){
        assert($('#ship_transfer_' + ship.id)).isVisible();
      });
    });

    it("sets ship in all command data", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var detail_cmd = details[7+c];
        assert(detail_cmd.data('ship')).equals(ship);;
      }
    });

    it("wires up command click events", function(){
      ship.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
        var detail_cmd = details[7+c];
        assert(detail_cmd).handles('click');
      }
    });

    describe("on command click", function(){
      it("invokes command handler", function(){
        ship.retrieve_details(page, details_cb);
        var details = details_cb.getCall(0).args[0];

        var stubs = [], cmds = [];
        for(var c = 0; c < Omega.Ship.prototype.cmds.length; c++){
          var scmd = Omega.Ship.prototype.cmds[c];
          stubs.push(sinon.stub(ship, scmd['handler']));
          cmds.push(details[7+c]);
        }

        $('#qunit-fixture').append(cmds);
        for(var c = 0; c < cmds.length; c++)
          cmds[c].click();
        for(var s = 0; s < stubs.length; s++)
          sinon.assert.calledWith(stubs[s], page);
      });
    });
  });

  describe("#clicked_in", function(){
    it("plays clicked audio effect", function(){
      var ship = new Omega.Ship();
      var canvas = {page : {audio_controls : {play : sinon.stub()}}};
      ship.clicked_in(canvas);
      sinon.assert.calledWith(canvas.page.audio_controls.play, 'click');
    });
  });

  describe("#selected", function(){
    it("sets mesh material emissive", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      ship.selected(Omega.Test.Page());
      assert(ship.mesh.tmesh.material.emissive.getHex()).equals(0xff0000);
    });
  });

  describe("#unselected", function(){
    it("resets mesh material emissive", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      ship.unselected(Omega.Test.Page());
      assert(ship.mesh.tmesh.material.emissive.getHex()).equals(0);
    })
  });

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

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = Omega.Ship.gfx;
      });

      after(function(){
        Omega.Ship.gfx = orig;
      });

      it("does nothing / just returns", function(){
        Omega.Ship.gfx = {'corvette' : {lamps:null}};
        new Omega.Ship({type:'corvette'}).load_gfx();
        assert(Omega.Ship.gfx['corvette'].lamps).isNull();
      });
    });

    it("creates mesh for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mesh).isOfType(Omega.ShipMesh);
      assert(Omega.Ship.gfx[ship.type].mesh.tmesh).isOfType(THREE.Mesh);
      assert(Omega.Ship.gfx[ship.type].mesh.tmesh.material).isOfType(Omega.ShipMeshMaterial);
      assert(Omega.Ship.gfx[ship.type].mesh.tmesh.geometry).isOfType(THREE.Geometry);
      /// TODO assert material texture & geometry src path values
    });

    it("creates highlight effects for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].highlight).isOfType(Omega.ShipHighlightEffects);
      assert(Omega.Ship.gfx[ship.type].highlight.mesh.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.Ship.gfx[ship.type].highlight.mesh.geometry).isOfType(THREE.CylinderGeometry);
    });

    it("creates lamps for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].lamps.olamps.length).
        equals(Omega.Config.resources.ships[ship.type].lamps.length);
      for(var l = 0; l < Omega.Ship.gfx[ship.type].lamps.length; l++){
        var lamp = Omega.Ship.gfx[ship.type].lamps[l];
        assert(lamp).isOfType(Omega.UI.CanvasLamp);
      }
    });

    it("creates trails for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      var conf = Omega.Config.resources.ships[ship.type].trails;
      assert(Omega.Ship.gfx[ship.type].trails).isOfType(Omega.ShipTrails);
      assert(Omega.Ship.gfx[ship.type].trails.particles).isOfType(ShaderParticleGroup);
      assert(Omega.Ship.gfx[ship.type].trails.particles.emitters.length).equals(conf.length);
    });

    it("creates attack vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].attack_vector).
        isOfType(Omega.ShipAttackVector);
      assert(Omega.Ship.gfx[ship.type].attack_vector.particles).
        isOfType(ShaderParticleGroup);
      assert(Omega.Ship.gfx[ship.type].attack_vector.particles.emitters.length).equals(1);
    });

    it("creates mining vector for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].mining_vector).
        isOfType(Omega.ShipMiningVector);
      assert(Omega.Ship.gfx[ship.type].mining_vector.particles).
        isOfType(ShaderParticleGroup);
      assert(Omega.Ship.gfx[ship.type].mining_vector.particles.emitters.length).
        equals(Omega.ShipMiningVector.prototype.num_emitters);
    });

    it("creates trajectory vectors for ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].trajectory1).isOfType(Omega.ShipTrajectory);
      assert(Omega.Ship.gfx[ship.type].trajectory2).isOfType(Omega.ShipTrajectory);
    });

    //it("creates progress bar for ship hp", function(){ // NIY
    //  var ship = Omega.Test.Canvas.Entities().ship;
    //  assert(Omega.Ship.gfx[ship.type].hp_bar).isOfType(Omega.UI.Canvas.ProgressBar);
    //})
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var config = Omega.Config;
    var ship;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      ship = new Omega.Ship({type: type,
        location : new Omega.Location({x: 100, y: -100, z: 200})});
    });

    after(function(){
      if(Omega.Ship.gfx){
        if(Omega.Ship.gfx[type].mesh && Omega.Ship.gfx[type].mesh.clone.restore) Omega.Ship.gfx[type].mesh.clone.restore();
        if(Omega.Ship.gfx[type].highlight && Omega.Ship.gfx[type].highlight.clone.restore) Omega.Ship.gfx[type].highlight.clone.restore();
        if(Omega.Ship.gfx[type].lamps)
          for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
            if(Omega.Ship.gfx[type].lamps[l].clone.restore)
              Omega.Ship.gfx[type].lamps[l].clone.restore();
        if(Omega.Ship.gfx[type].trails && Omega.Ship.gfx[type].trails.clone.restore)
          Omega.Ship.gfx[type].trails.clone.restore();
        if(Omega.Ship.gfx[type].attack_vector && Omega.Ship.gfx[type].attack_vector.clone.restore) Omega.Ship.gfx[type].attack_vector.clone.restore();
        if(Omega.Ship.gfx[type].mining_vector && Omega.Ship.gfx[type].mining_vector.clone.restore) Omega.Ship.gfx[type].mining_vector.clone.restore();
        if(Omega.Ship.gfx[type].trajectory1 && Omega.Ship.gfx[type].trajectory1.clone.restore) Omega.Ship.gfx[type].trajectory1.clone.restore();
        if(Omega.Ship.gfx[type].trajectory2 && Omega.Ship.gfx[type].trajectory2.clone.restore) Omega.Ship.gfx[type].trajectory2.clone.restore();
        if(Omega.Ship.gfx[type].hp_bar && Omega.Ship.gfx[type].hp_bar.clone.restore) Omega.Ship.gfx[type].hp_bar.clone.restore();
      }
      if(Omega.Ship.prototype.retrieve_resource.restore)
        Omega.Ship.prototype.retrieve_resource.restore();
    });

    it("loads ship gfx", function(){
      var ship   = new Omega.Ship({type: type});
      var load_gfx  = sinon.spy(ship, 'load_gfx');
      ship.init_gfx(config, type);
      sinon.assert.called(load_gfx);
    });

    it("clones template mesh", function(){
      var mesh = new Omega.ShipMesh(new THREE.Mesh());
      var cloned = new Omega.ShipMesh(new THREE.Mesh());

      var retrieve_resource = sinon.stub(Omega.Ship.prototype, 'retrieve_resource');
      ship.init_gfx(config, type);
      sinon.assert.calledWith(retrieve_resource, 'template_mesh_' + ship.type, sinon.match.func);
      var retrieve_resource_cb = retrieve_resource.getCall(0).args[1];

      var clone = sinon.stub(mesh, 'clone').returns(cloned);
      retrieve_resource_cb(mesh);
      assert(ship.mesh).equals(cloned);
    });

    it("sets mesh base position/rotation", function(){
      ship.init_gfx(config, type);
      var template_mesh = Omega.Ship.gfx[ship.type].mesh;
      assert(ship.mesh.base_position).equals(template_mesh.base_position);
      assert(ship.mesh.base_rotation).equals(template_mesh.base_rotation);
    });

    it("sets mesh omega_entity", function(){
      ship.init_gfx(config, type);
      assert(ship.mesh.omega_entity).equals(ship);
    });

    it("updates_gfx in mesh cb", function(){
      var retrieve_resource = sinon.stub(Omega.Ship.prototype, 'retrieve_resource');
      ship.init_gfx(config, type);
      var retrieve_resource_cb = retrieve_resource.getCall(0).args[1];

      var update_gfx = sinon.spy(ship, 'update_gfx');
      retrieve_resource_cb(Omega.Ship.gfx[ship.type].mesh);
      sinon.assert.called(update_gfx);
    });

    it("adds mesh to components", function(){
      ship.init_gfx(config, type);
      assert(ship.components).includes(ship.mesh.tmesh);
    });

    it("clones Ship highlight effects", function(){
      var mesh = new Omega.ShipHighlightEffects();
      sinon.stub(Omega.Ship.gfx[type].highlight, 'clone').returns(mesh);
      ship.init_gfx(config, type);
      assert(ship.highlight).equals(mesh);
    });

    it("sets omega_entity on highlight effects", function(){
      ship.init_gfx(config, type);
      assert(ship.highlight.omega_entity).equals(ship);
    });

    it("clones Ship lamps", function(){
      var spies = [];
      var lamps = Omega.Ship.gfx[type].lamps.olamps;
      for(var l = 0; l < lamps.length; l++)
        spies.push(sinon.spy(lamps[l], 'clone'));
      ship.init_gfx(config, type);
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("clones Ship trails", function(){
      var trails = new Omega.ShipTrails();
      sinon.stub(Omega.Ship.gfx[ship.type].trails, 'clone').returns(trails);
      ship.init_gfx(config, type);
      assert(ship.trails).equals(trails);
    });

    it("clones Ship attack vector", function(){
      var mesh = new Omega.ShipAttackVector();
      sinon.stub(Omega.Ship.gfx[type].attack_vector, 'clone').returns(mesh);
      ship.init_gfx(config, type);
      assert(ship.attack_vector).equals(mesh);
    });

    it("clones Ship mining vector", function(){
      var mesh = new Omega.ShipMiningVector();
      sinon.stub(Omega.Ship.gfx[type].mining_vector, 'clone').returns(mesh);
      ship.init_gfx(config, type);
      assert(ship.mining_vector).equals(mesh);
    });

    it("clones Ship trajectory vectors", function(){
      var line1 = Omega.Ship.gfx[type].trajectory1.clone();
      var line2 = Omega.Ship.gfx[type].trajectory1.clone();
      sinon.stub(Omega.Ship.gfx[type].trajectory1, 'clone').returns(line1);
      sinon.stub(Omega.Ship.gfx[type].trajectory2, 'clone').returns(line2);
      ship.init_gfx(config, type);
      assert(ship.trajectory1).equals(line1);
      assert(ship.trajectory2).equals(line2);
    });

    describe("debug graphics are enabled", function(){
      it("adds trajectory graphics to components", function(){
        ship.debug_gfx = true;
        ship.init_gfx(config, type);
        assert(ship.components).includes(ship.trajectory1.mesh);
        assert(ship.components).includes(ship.trajectory2.mesh);
      });
    });

    it("clones Ship hp progress bar", function(){
      var hp_bar = Omega.Ship.gfx[type].hp_bar.clone(); 
      sinon.stub(Omega.Ship.gfx[type].hp_bar, 'clone').returns(hp_bar);
      ship.init_gfx(config, type);
      assert(ship.hp_bar).equals(hp_bar);
    });

    it("sets scene components to ship mesh, highlight effects, lamps, trails, hp-bar components", function(){
      ship.init_gfx(config, type);
      assert(ship.components).includes(ship.mesh.tmesh);
      assert(ship.components).includes(ship.highlight.mesh);
      assert(ship.components).includes(ship.trails.particles.mesh);
      assert(ship.components).includes(ship.hp_bar.bar.component1);
      assert(ship.components).includes(ship.hp_bar.bar.component2);
      for(var l = 0; l < ship.lamps.olamps.length; l++)
        assert(ship.components).includes(ship.lamps.olamps[l].component);
      /// TODO particle components
    });

    it("updates_gfx", function(){
      var update_gfx = sinon.spy(ship, 'update_gfx');
      ship.init_gfx(config, type);
      sinon.assert.called(update_gfx);
    });
  });

  describe("#cp_gfx", function(){
    var orig, ship;
    before(function(){
      orig = {components        : 'components',
              shader_components : 'shader_components',
              mesh              : 'mesh',
              highlight         : 'highlight',
              lamps             : 'lamp',
              trails            : 'trails',
              attack_vector     : 'attack_vector',
              mining_vector     : 'mining_vector',
              trajectory1       : 'trajectory1',
              trajectory2       : 'trajectory2',
              hp_bar            : 'hp_bar' };
      ship = new Omega.Ship();
    });

    it("copies components from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.components).equals(orig.components);
    });

    it("copies shader components from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.shader_components).equals(orig.shader_components);
    });

    it("copies mesh from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.mesh).equals(orig.mesh);
    });

    it("copies highlight from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.highlight).equals(orig.highlight);
    });

    it("copies lamps from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.lamps).equals(orig.lamps);
    });

    it("copies trails from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.trails).equals(orig.trails);
    });

    it("copies attack_vector from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.attack_vector).equals(orig.attack_vector);
    });

    it("copies mining_vector from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.mining_vector).equals(orig.mining_vector);
    });

    it("copies trajectories from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.trajectory1).equals(orig.trajectory1);
      assert(ship.trajectory2).equals(orig.trajectory2);
    });

    it("copies hp bar from specified entity", function(){
      ship.cp_gfx(orig);
      assert(ship.hp_bar).equals(orig.hp_bar);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      var ship = new Omega.Ship({type : 'corvette', location :
                   new Omega.Location({movement_strategy : {}})});
      ship.init_gfx();

      var spies = [];
      for(var l = 0; l < ship.lamps.olamps.length; l++)
        spies.push(sinon.spy(ship.lamps.olamps[l], 'run_effects'))

      ship.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    /// it("runs trail effects"); // NIY
    /// it("moves ship according to movement strategy"); // NIY
    /// it("runs attack effects"); // NIY
    /// it("runs mining effects"); // NIY
  });

  describe("#update_gfx", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({type : 'corvette', location : new Omega.Location()});
      ship.init_gfx();
    });

    it("updates mesh", function(){
      var update = sinon.spy(ship.mesh, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates highlight effects", function(){
      var update = sinon.spy(ship.highlight, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates lamps", function(){
      var update = sinon.spy(ship.lamps, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates trails", function(){
      var update = sinon.spy(ship.trails, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates trajectories", function(){
      var update1 = sinon.spy(ship.trajectory1, 'update');
      var update2 = sinon.spy(ship.trajectory2, 'update');
      ship.update_gfx();
      sinon.assert.calledWith(update1, 'primary');
      sinon.assert.calledWith(update2, 'secondary');
    });

    it("updates hp bar", function(){
      var update = sinon.spy(ship.hp_bar, 'update');
      ship.update_gfx();
      sinon.assert.called(update);
    });

    it("updates command vectors", function(){
      var update_attack = sinon.spy(ship.attack_vector, 'update');
      var update_mining = sinon.spy(ship.mining_vector, 'update');
      ship.update_gfx();
      sinon.assert.called(update_attack);
      sinon.assert.called(update_mining);
    });
  });

  describe("#get", function(){
    var node, get_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      get_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufacutred::get_entity request", function(){
      Omega.Ship.get('ship1', node, get_cb);
      sinon.assert.calledWith(invoke_spy,
        'manufactured::get_entity',
        'with_id', 'ship1', sinon.match.func);
    });

    describe("manufactured::get_entity callback", function(){
      var invoke_cb;
      before(function(){
        Omega.Ship.get('ship1', node, get_cb);
        invoke_cb = invoke_spy.getCall(0).args[3];
      });

      it("invokes callback with ship", function(){
        invoke_cb({result : {id: '42'}});
        sinon.assert.calledWith(get_cb, sinon.match.ofType(Omega.Ship), null);
      });

      describe("error received", function(){
        it("invokes callback with error", function(){
          invoke_cb({error : {message : "err"}});
          sinon.assert.calledWith(get_cb, null, "err");
        });
      });
    });
  });

  describe("#owned_by", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Ship.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'owned_by', 'user1');
    });

    describe("manufactured::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new ship instances", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id: 'sh1'},{id: 'sh2'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(2);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
        assert(ships[1]).isOfType(Omega.Ship);
        assert(ships[1].id).equals('sh2');
      });
    });
  });

  describe("#under", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node         = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy   = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Ship.under('system1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'under', 'system1');
    });

    describe("manufactured::get_entities callback", function(){
      it("invokes callback", function(){
        Omega.Ship.under('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("converts results to ship instances", function(){
        Omega.Ship.under('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id : 'sh1'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(1);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
      });
    });
  });
});}); // Omega.Ship

pavlov.specify("Omega.ShipMesh", function(){
describe("Omega.ShipMesh", function(){
  describe("#update", function(){
    var loc, mesh;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      mesh = new Omega.ShipMesh(new THREE.Mesh());
      mesh.omega_entity = { location : loc };
    });

    after(function(){
      if(Omega.set_rotation.restore) Omega.set_rotation.restore();
    });

    it("sets mesh position", function(){
      mesh.base_position = [10,20,-30];
      mesh.update();
      assert(mesh.tmesh.position.x).equals(loc.x + 10);
      assert(mesh.tmesh.position.y).equals(loc.y + 20);
      assert(mesh.tmesh.position.z).equals(loc.z - 30);
    });

    it("rotates mesh", function(){
      var rotate = sinon.spy(Omega, 'set_rotation');
      mesh.base_rotation = [0.01, 0.02, -0.03]
      mesh.update();
      sinon.assert.calledWith(rotate, mesh.tmesh);
      assert(rotate.getCall(0).args[1]).isSameAs(mesh.base_rotation);
      assert(rotate.getCall(1).args[1].elements).
        isSameAs(loc.rotation_matrix().elements);
    });
  });
});}); // Omega.ShipMesh

pavlov.specify("Omega.ShipHighlightEffects", function(){
describe("Omega.ShipHighlightEffects", function(){
  describe("#update", function(){
    var loc, highlight;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      highlight = new Omega.ShipHighlightEffects(new THREE.Mesh());
      highlight.omega_entity = {location : loc};
    });

    it("sets highlight postion", function(){
      var props = Omega.ShipHighlightEffects.prototype.highlight_props;
      highlight.update();
      assert(highlight.mesh.position.x).equals(loc.x + props.x);
      assert(highlight.mesh.position.y).equals(loc.y + props.y);
      assert(highlight.mesh.position.z).equals(loc.z + props.z);
    });
  });
});}); // Omega.ShipHighlightEffects

pavlov.specify("Omega.ShipLamps", function(){
describe("Omega.ShipLamps", function(){
  describe("#update", function(){
    var loc, lamps;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      lamps = new Omega.ShipLamps(Omega.Config, 'corvette');
      lamps.init_gfx();
      lamps.omega_entity = {location: loc};
    });

    after(function(){
      if(Omega.rotate_position.restore) Omega.rotate_position.restore();
    });

    it("sets & rotates lamps' position", function(){
      var rotate = sinon.spy(Omega, 'rotate_position');
      var rot_matrix = loc.rotation_matrix();
      lamps.update();

      var config_lamps = Omega.Config.resources.ships['corvette'].lamps;
      for(var l = 0; l < config_lamps.length; l++){
        var config_lamp = config_lamps[l];
        var lamp = lamps.olamps[l];
        assert(lamp.component.position.x).equals(loc.x + config_lamp[2][0]);
        assert(lamp.component.position.y).equals(loc.y + config_lamp[2][1]);
        assert(lamp.component.position.z).equals(loc.z + config_lamp[2][2]);
        sinon.assert.calledWith(rotate, lamp.component, rot_matrix);
      }
    });
  });
});}); // Omega.ShipHighlightEffects

pavlov.specify("Omega.ShipTrails", function(){
describe("Omega.ShipTrails", function(){
  describe("#update", function(){
    var loc, trails;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      trails = new Omega.ShipTrails(Omega.Config, 'corvette');
      trails.omega_entity = {location: loc};
    });

    after(function(){
      if(Omega.set_rotation.restore) Omega.set_rotation.restore();
      if(Omega.rotate_position.restore) Omega.rotate_position.restore();
    });

    //it("sets trail positions, orientation, and velocity", function(){ /// NIY
    //  var set_rotation = sinon.spy(Omega, 'set_rotation');
    //  var rotate_position = sinon.spy(Omega, 'rotate_position');
    //  var rot_matrix = loc.rotation_matrix();
    //  trails.update();
    //});
  });
});}); // Omega.ShipTrails

pavlov.specify("Omega.ShipTrajectory", function(){
describe("Omega.ShipTrajectory", function(){
  describe("#update", function(){
    var loc, trajectory;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      trajectory = new Omega.ShipTrajectory();
      trajectory.omega_entity = {location: loc};
    });

    it("sets position of primary trajectory", function(){
      trajectory.update('primary');
      assert(trajectory.mesh.position.x).equals(loc.x);
      assert(trajectory.mesh.position.y).equals(loc.y);
      assert(trajectory.mesh.position.z).equals(loc.z);
    });

    it("sets position of secondary trajectory", function(){
      trajectory.update('secondary');
      assert(trajectory.mesh.position.x).equals(loc.x);
      assert(trajectory.mesh.position.y).equals(loc.y);
      assert(trajectory.mesh.position.z).equals(loc.z);
    });

    //it("sets trajectory vertices to be aligned w/ orientation"); /// NIY

    it("marks trajectory geometry as needing update", function(){
      trajectory.update();
      assert(trajectory.mesh.geometry.verticesNeedUpdate).equals(true);
    });
  });
});}); // Omega.ShipTrajectory

pavlov.specify("Omega.ShipHpBar", function(){
describe("Omega.ShipHpBar", function(){
  describe("#_update_hp_bar", function(){
    var loc, hp_bar;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      hp_bar = new Omega.ShipHpBar();
      hp_bar.init_gfx();
      hp_bar.omega_entity = {location: loc, hp : 10.0, max_hp : 100.0};
    });

    it("updates hp progress bar", function(){
      var update = sinon.spy(hp_bar.bar, 'update');
      hp_bar.update();
      sinon.assert.calledWith(update, loc, 0.1);
    });
  });
});}); // Omega.ShipTrajectory

pavlov.specify("Omega.ShipAttackVector", function(){
describe("Omega.ShipAttackVector", function(){
  describe("#update", function(){
    var loc, vector;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});
      vector = new Omega.ShipAttackVector();
      vector.omega_entity = {location : loc};
    });

    it("sets attack vector position", function(){
      vector.update();
      assert(vector.particles.emitters[0].position.x).equals(loc.x);
      assert(vector.particles.emitters[0].position.y).equals(loc.y);
      assert(vector.particles.emitters[0].position.z).equals(loc.z);
    });
  });
});}); /// Omega.ShipAttackVector

pavlov.specify("Omega.ShipMiningVector", function(){
describe("Omega.ShipMiningVector", function(){
  describe("#update", function(){
    var loc, vector;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});
      vector = new Omega.ShipMiningVector();
      vector.omega_entity = {location : loc};
    });

    //it("sets mining vector velocity", function(){ /// NIY
    //});
  });
});}); /// Omega.ShipMiningVector
