// Test mixin usage through ship
pavlov.specify("Omega.ShipInteraction", function(){
describe("Omega.ShipInteraction", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    page = Omega.Test.Page();
  });

  describe("#_should_move_to", function(){
    describe("asteroid, station, or jump gate", function(){
      it("returns true", function(){
        assert(ship._should_move_to(new Omega.Asteroid())).isTrue();
        assert(ship._should_move_to(new Omega.Station())).isTrue();
        assert(ship._should_move_to(new Omega.JumpGate())).isTrue();
      });
    });

    describe("anything else", function(){
      it("returns false", function(){
        assert(ship._should_move_to(new Omega.Ship())).isFalse();
      });
    });
  });

  describe("#_should_follow", function(){
    describe("ship or planet", function(){
      it("returns true", function(){
        assert(ship._should_follow(new Omega.Ship())).isTrue();
        assert(ship._should_follow(new Omega.Planet())).isTrue();
      });
    });

    describe("anything else", function(){
      it("returns false", function(){
        assert(ship._should_follow(new Omega.Station())).isFalse();
      });
    });
  });

  describe("#context_action", function(){
    before(function(){
      page.set_session(new Omega.Session({user_id : 'user1'}));
      ship.user_id = 'user1';

      /// stub out move / follow calls
      sinon.spy(ship, '_move');
      sinon.spy(ship, '_follow');
    });

    after(function(){
      page.restore_session();
    });

    describe("user not logged in", function(){
      it("does not invoke move/follow", function(){
        page.session = null;
        ship.context_action(new Omega.Ship(), page);
        sinon.assert.notCalled(ship._move);
        sinon.assert.notCalled(ship._follow);
      });
    });

    describe("user does not own ship", function(){
      it("does not invoke move/follow", function(){
        ship.user_id = 'foo';
        ship.context_action(new Omega.Ship(), page);
        sinon.assert.notCalled(ship._move);
        sinon.assert.notCalled(ship._follow);
      });
    });

    describe("_should_move_to entity returns true", function(){
      it("moves to entity + offset", function(){
        sinon.stub(ship, '_should_move_to').returns(true);

        var loc = new Omega.Location();
        loc.set(100, 100, 100);
        var entity = new Omega.Station({location : loc});
        ship.context_action(entity, page);
        sinon.assert.calledWith(ship._move, page);

        var config_offset = Omega.Config.movement_offset;
        var move_offset   = ship._move.getCall(0).args;
        for(var o = 1; o < 4; o++){
          assert(move_offset[o]).isLessThan(100 + config_offset.max);
          assert(move_offset[o]).isGreaterThan(100 + config_offset.min);
        }
      });
    });

    describe("_should_follow entity returns true", function(){
      it("follows entity", function(){
        sinon.stub(ship, '_should_move_to').returns(false);
        sinon.stub(ship, '_should_follow').returns(true);
        ship.context_action({id : 'entity1'}, page);
        sinon.assert.calledWith(ship._follow, page, 'entity1')
      });
    });
  });

  describe("#_stations_in_same_system", function(){
    var station1, station2, station3;

    before(function(){
      ship.system_id = 'system1';
      station1 = Omega.Gen.station({system_id : ship.system_id});
      station2 = Omega.Gen.station({system_id : ship.system_id});
      station3 = Omega.Gen.station({system_id : 'foobar'});
      page.entity(station1.id, station1);
      page.entity(station2.id, station2);
      page.entity(station3.id, station3);
    });

    after(function(){
      page.entities = [];
    });

    it("returns list of stations in the same system as ship", function(){
      assert(ship._stations_in_same_system(page)).isSameAs([station1, station2]);
    });
  });

  describe("#_ships_in_same_system", function(){
    var ship1, ship2, ship3;

    before(function(){
      ship.system_id = 'system1';
      ship1 = Omega.Gen.ship({system_id : ship.system_id});
      ship2 = Omega.Gen.ship({system_id : ship.system_id});
      ship3 = Omega.Gen.ship({system_id : 'foobar'});
      page.entity(ship1.id, ship1);
      page.entity(ship2.id, ship2);
      page.entity(ship3.id, ship3);
    });

    after(function(){
      page.entities = [];
    });

    it("returns list of ships in the same system as ship", function(){
      assert(ship._ships_in_same_system(page)).isSameAs([ship1, ship2]);
    });

    it("does not return local ship", function(){
      page.entity(ship.id, ship);
      assert(ship._ships_in_same_system(page)).doesNotInclude(ship);
    });
  });

  describe("#_select_destination", function(){
    var ship1, station1, asteroid1, jg1;

    before(function(){
      page.set_canvas_root(Omega.Gen.solar_system());
      sinon.stub(ship, '_stations_in_same_system').returns([station1])
      sinon.stub(ship, '_ships_in_same_system').returns([ship1])
      sinon.stub(page.canvas.root, 'asteroids').returns([asteroid1]);
      sinon.stub(page.canvas.root, 'jump_gates').returns([jg1]);
    });

    after(function(){
      page.restore_canvas_root();
    });

    it("shows select destination dialog", function(){
      sinon.stub(ship.dialog(), 'show_destination_selection_dialog');
      ship._select_destination(page);
      sinon.assert.calledWith(ship.dialog().show_destination_selection_dialog,
                              page, ship, sinon.match.object);
    });

    it("retrieves entities to render in destination select box", function(){
      var show_dialog = sinon.stub(ship.dialog(), 'show_destination_selection_dialog');
      ship._select_destination(page);

      var entities = show_dialog.getCall(0).args[2];
      assert(entities['stations']).isSameAs([station1]);
      assert(entities['ships']).isSameAs([ship1]);
      assert(entities['asteroids']).isSameAs([asteroid1]);
      assert(entities['jump_gates']).isSameAs([jg1]);
    });
  });

  describe("#_move", function(){
    before(function(){
      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::move_entity with updated location", function(){
      ship._move(page, 100, 200, -50);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::move_entity', ship.id,
        sinon.match.loc(100, 200, -50), sinon.match.func);
      assert(page.node.http_invoke.getCall(0).args[2]).isNotEqualTo(ship.loc);
    });

    describe("on manufactured::move_entity response", function(){
      var response_cb;

      before(function(){
        ship._move(page, 100, 200, -50);
        response_cb = page.node.http_invoke.omega_callback();
      })

      describe("on failure", function(){
        it("invokes _move_failed", function(){
          var response = {error  : {message : 'move err'}};
          sinon.stub(ship, '_move_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._move_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _move_success", function(){
          var response = {result : Omega.Gen.ship()};
          sinon.stub(ship, '_move_success');
          response_cb(response);
          sinon.assert.calledWith(ship._move_success, response, page);
        });
      });
    });
  });

  describe("#_move_failed", function(){
    var response = {error  : {message : 'move err'}};

    it("clears error dialog", function(){
      sinon.stub(ship.dialog(), 'clear_errors');
      ship._move_failed(response);
      sinon.assert.called(ship.dialog().clear_errors);
    });

    it("shows error dialog", function(){
      sinon.stub(ship.dialog(), 'show_error_dialog');
      ship._move_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._move_failed(response);
      assert(ship.dialog().title).equals('Movement Error');
    });

    it("appends error to dialog", function(){
      sinon.stub(ship.dialog(), 'append_error');
      ship._move_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'move err');
    });
  });

  describe("#_move_success", function(){
    var nship, response;

    before(function(){
      nship = Omega.Gen.ship();
      response = {result : nship};
      sinon.stub(page.canvas, 'reload');
    })

    after(function(){
      page.canvas.reload.restore();
    });

    it("hides the dialog", function(){
      sinon.stub(ship.dialog(), 'hide');
      ship._move_success(response, page);
      sinon.assert.called(ship.dialog().hide);
    });

    it("updates ship movement strategy", function(){
      ship._move_success(response, page);
      assert(ship.location.movement_strategy).equals(nship.location.movement_strategy);
    });

    it("reloads ship in canvas scene", function(){
      ship._move_success(response, page);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      sinon.spy(ship, 'update_gfx');
      ship._move_success(response, page);
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });
  });

  describe("#follow", function(){
    before(function(){
      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::follow_entity", function(){
      ship._follow(page, 'shipA');
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::follow_entity', ship.id, 'shipA',
        Omega.Config.follow_distance, sinon.match.func);
    });

    describe("on manufactured::follow_entity response", function(){
      var response_cb;

      before(function(){
        ship._follow(page, 'shipA');
        response_cb = page.node.http_invoke.omega_callback();
      })

      describe("on failure", function(){
        it("invokes _follow_failed", function(){
          var response = {error  : {message : 'follow err'}};
          sinon.stub(ship, '_follow_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._follow_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _follow_success", function(){
          var response = {result : Omega.Gen.ship()};
          sinon.stub(ship, '_follow_success');
          response_cb(response);
          sinon.assert.calledWith(ship._follow_success, response, page);
        });
      });
    });
  });

  describe("#_follow_failed", function(){
    var response = {error  : {message : 'follow err'}};

    it("clears error dialog", function(){
      sinon.stub(ship.dialog(), 'clear_errors');
      ship._follow_failed(response);
      sinon.assert.called(ship.dialog().clear_errors);
    });

    it("shows error dialog", function(){
      sinon.stub(ship.dialog(), 'show_error_dialog');
      ship._follow_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._follow_failed(response);
      assert(ship.dialog().title).equals('Movement Error');
    });

    it("appends error to dialog", function(){
      sinon.stub(ship.dialog(), 'append_error');
      ship._follow_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'follow err');
    });
  });

  describe("#_follow_success", function(){
    var nship, response;

    before(function(){
      nship = Omega.Gen.ship();
      response = {result : nship};
      sinon.stub(page.canvas, 'reload');
    })

    after(function(){
      page.canvas.reload.restore();
    });

    it("hides the dialog", function(){
      sinon.stub(ship.dialog(), 'hide');
      ship._follow_success(response, page);
      sinon.assert.called(ship.dialog().hide);
    });

    it("updates ship movement strategy", function(){
      ship._follow_success(response, page);
      assert(ship.location.movement_strategy).equals(nship.location.movement_strategy);
    });

    it("reloads ship in canvas scene", function(){
      ship._follow_success(response, page);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      sinon.spy(ship, 'update_gfx');
      ship._follow_success(response, page);
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });
  });

  describe("#attack_targets", function(){
    before(function(){
      page.set_session(new Omega.Session({user_id : 'user1'}));
      ship.attack_distance = 50;

      /// by default, all will be returned
      page.entities = [];
      for(var e = 0; e < 5; e++){
        var eship = Omega.Gen.ship({user_id : 'user2', hp : 100});
        eship.location.set(0, 0, 0);
        page.entities.push(eship);
      }

      page.entities[0].user_id = 'user1';             /// user owned
      page.entities[2].location.set(5, 5, 5);         /// within valid distance
      page.entities[3].location.set(1000, 1000, 1000) /// outside valid distance
      page.entities[4].hp = 0;                        /// not alive
    });

    after(function(){
      page.restore_session();
      page.restore_entities();
    });

    it("returns all non-user-owned ships in vicinity that are alive", function(){
      assert(ship._attack_targets(page)).isSameAs([page.entities[1],
                                                   page.entities[2]]);
    });
  });

  describe("#select_attack_target", function(){
    it("shows attack dialog w/ attack targets", function(){
      var ships = [Omega.Gen.ship(), Omega.Gen.ship()];
      sinon.stub(ship, '_attack_targets').returns(ships)
      sinon.stub(ship.dialog(), 'show_attack_dialog');
      ship._select_attack_target(page);
      sinon.assert.calledWith(ship.dialog().show_attack_dialog,
                              page, ship, ships);
    });
  });

  describe("#_start_attacking", function(){
    var tgt, evnt;

    before(function(){
      tgt = Omega.Gen.ship();
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('target', tgt);

      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::attack_entity with command target", function(){
      ship._start_attacking(page, evnt);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::attack_entity', ship.id, tgt.id, sinon.match.func);
    });

    describe("on manufactured::attack_entity response", function(){
      var response_cb;

      before(function(){
        ship._start_attacking(page, evnt);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _attack_failed", function(){
          var response = {error  : {message : 'attack err'}};
          sinon.stub(ship, '_attack_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._attack_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _attack_success", function(){
          var nship = new Omega.Ship({attacking : tgt});
          var response = {result : nship};
          sinon.stub(ship, '_attack_success');
          response_cb(response);
          sinon.assert.calledWith(ship._attack_success, response);
        })
      });
    });
  });

  describe("#_attack_failed", function(){
    var response = {error  : {message : 'attack err'}};

    it("shows error dialog", function(){
      sinon.stub(ship.dialog(), 'show_error_dialog');
      ship._attack_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._attack_failed(response);
      assert(ship.dialog().title).equals('Attack Error');
    });

    it("appends error to dialog", function(){
      sinon.stub(ship.dialog(), 'append_error');
      ship._attack_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'attack err');
    });
  });

  describe("#_attack_success", function(){
    var nship, tgt, response;

    before(function(){
     sinon.stub(page.canvas, 'reload');

     tgt      = Omega.Gen.ship();
     nship    = Omega.Gen.ship();
     response = {result : nship};
    })

    after(function(){
      page.canvas.reload.restore();
    });

    it("hides the dialog", function(){
      sinon.stub(ship.dialog(), 'hide');
      ship._attack_success(response, page, tgt);
      sinon.assert.called(ship.dialog().hide);
    });

    it("updates ship attack target", function(){
      ship._attack_success(response, page, tgt);
      assert(ship.attacking).equals(tgt);
    });

    it("reloads ship in canvas scene", function(){
      ship._attack_success(response, page, tgt);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      ship._attack_success(response, page, tgt);
      sinon.spy(ship, 'update_gfx');
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });
  });

  describe("#_docking_targets", function(){
    before(function(){
      page.set_session(new Omega.Session({user_id : 'user1'}));

      /// by default, all will be returned
      page.entities = [];
      for(var e = 0; e < 4; e++){
        var station = Omega.Gen.station({user_id : 'user1',
                                         docking_distance : 100});
        station.location.set(0, 0, 0);
        page.entities.push(station);
      }

      /// ships won't be returned
      var ship1 = Omega.Gen.ship({user_id : 'user1'});
      ship1.location.set(0, 0, 0);
      page.entities.push(ship1);

      page.entities[1].location.set(5, 0, 5);          /// within valid distance
      page.entities[2].user_id = 'user2';              /// other user
      page.entities[3].location.set(1000, 1000, 1000); /// outside valid distance
    });

    after(function(){
      page.restore_session();
      page.restore_entities();
    });

    it("returns list of user-owned stations within vicinity of ship", function(){
      assert(ship._docking_targets(page)).isSameAs([page.entities[0], page.entities[1]]);
    });
  })

  describe("#_select_docking_station", function(){
    it("shows docking dialog w/ docking targets", function(){
      var station1 = Omega.Gen.station();
      var station2 = Omega.Gen.station();
      var stations = [station1, station2];
      sinon.stub(ship, '_docking_targets').returns(stations)

      sinon.spy(ship.dialog(), 'show_docking_dialog');
      ship._select_docking_station(page);
      sinon.assert.calledWith(ship.dialog().show_docking_dialog,
                              page, ship, stations);

    });
  });

  describe("#_dock", function(){
    var station, evnt;

    before(function(){
      station = new Omega.Station({id : 'station1'});
      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('station', station);

      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufacured::dock with command station", function(){
      ship._dock(page, evnt);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::dock', ship.id, station.id, sinon.match.func);
    });

    describe("on manufactured::dock response", function(){
      var response_cb;

      before(function(){
        ship._dock(page, evnt);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _dock_failure", function(){
          var response = {error : {message : 'dock error'}};
          sinon.spy(ship, '_dock_failure');
          response_cb(response);
          sinon.assert.calledWith(ship._dock_failure, response);
        });
      });

      describe("on success", function(){
        it("invokes _dock_success", function(){
          var response = {result : Omega.Gen.ship()};
          sinon.spy(ship, '_dock_success');
          response_cb(response);
          sinon.assert.calledWith(ship._dock_success, response, page, station);
        });
      });
    });
  });

  describe("#_dock_failure", function(){
    var response = {error : {message : 'dock error'}};

    it("shows error dialog", function(){
      sinon.spy(ship.dialog(), 'show_error_dialog');
      ship._dock_failure(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._dock_failure(response);
      assert(ship.dialog().title).equals('Docking Error');
    });

    it("appends error to dialog", function(){
      sinon.spy(ship.dialog(), 'append_error');
      ship._dock_failure(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'dock error');
    });
  });

  describe("#_dock_success", function(){
    var response, station;

    before(function(){
      station = Omega.Gen.station();
      response = {result : Omega.Gen.ship({docked_at : station})};

      sinon.stub(page.canvas, 'reload');
      sinon.spy(page.canvas.entity_container, 'refresh');
    });

    after(function(){
      page.canvas.reload.restore();
      page.canvas.entity_container.refresh.restore();
    });

    it("hides the dialog", function(){
      sinon.spy(ship.dialog(), 'hide');
      ship._dock_success(response, page, station);
      sinon.assert.called(ship.dialog().hide);
    });

    it("updates ship docked at entity", function(){
      ship._dock_success(response, page, station);
      assert(ship.docked_at).equals(station);
    });

    it("updates ship docked at id", function(){
      ship._dock_success(response, page, station);
      assert(ship.docked_at_id).equals(station.id);
    });

    it("reloads ship in canvas scene", function(){
      ship._dock_success(response, page, station);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      ship._dock_success(response, page, station);
      sinon.spy(ship, 'update_gfx');
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });

    it("refreshes entity container", function(){
      ship._dock_success(response, page, station);
      sinon.assert.called(page.canvas.entity_container.refresh);
    });
  });

  describe("#_undock", function(){
    before(function(){
      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::undock", function(){
      ship._undock(page);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::undock', ship.id, sinon.match.func);
    });

    describe("on manufactured::undock response", function(){
      var response_cb;

      before(function(){
        ship._undock(page);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _undock_failure", function(){
          var response = {error : {message : 'undock error'}};
          sinon.spy(ship, '_undock_failure');
          response_cb(response);
          sinon.assert.calledWith(ship._undock_failure, response);
        });
      });

      describe("on success", function(){
        it("invokes _undock_success", function(){
          var response = {result : Omega.Gen.ship()};
          sinon.spy(ship, '_undock_success');
          response_cb(response);
          sinon.assert.calledWith(ship._undock_success, response, page);
        });
      });
    });
  });

  describe("#_undock_failure", function(){
    var response = {error : {message : 'undock error'}};

    it("shows error dialog", function(){
      sinon.spy(ship.dialog(), 'show_error_dialog');
      ship._undock_failure(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._undock_failure(response);
      assert(ship.dialog().title).equals('Undocking Error');
    });

    it("appends error to dialog", function(){
      var append = sinon.spy(ship.dialog(), 'append_error');
      ship._undock_failure(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'undock error');
    });
  });

  describe("#_undock_success", function(){
    var response;

    before(function(){
      response = {result : Omega.Gen.ship({})};

      sinon.stub(page.canvas, 'reload');
      sinon.spy(page.canvas.entity_container, 'refresh');
    });

    after(function(){
      page.canvas.reload.restore();
      page.canvas.entity_container.refresh.restore();
    });

    it("clears ship docked_at entity", function(){
      ship._undock_success(response, page);
      assert(ship.docked_at).isNull();
    });

    it("clears ship docked_at_id", function(){
      ship._undock_success(response, page);
      assert(ship.docked_at_id).isNull();
    });

    it("reloads ship in canvas scene", function(){
      ship._undock_success(response, page);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      ship._undock_success(response, page);
      sinon.spy(ship, 'update_gfx');
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });

    it("refreshes entity container", function(){
      ship._undock_success(response, page);
      sinon.assert.called(page.canvas.entity_container.refresh);
    });
  });

  describe("#_transfer", function(){
    before(function(){
      ship.docked_at_id = 'station1';

      var res1 = new Omega.Resource();
      var res2 = new Omega.Resource();
      ship.resources = [res1, res2];

      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::transfer_resource with all ship resources", function(){
      ship._transfer(page);
      for(var r = 0; r < ship.resources.length; r++)
        sinon.assert.calledWith(page.node.http_invoke,
          'manufactured::transfer_resource', ship.id,
          ship.docked_at_id, ship.resources[r], sinon.match.func);
    });

    describe("on manufactured::transfer_resource response", function(){
      var response_cb;

      before(function(){
        ship._transfer(page);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _transfer_failed", function(){
          var response = {error : {message : 'transfer error'}};
          sinon.stub(ship, '_transfer_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._transfer_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _transfer_success", function(){
          var eship = Omega.Gen.ship();
          var estation = Omega.Gen.station();
          var response = {result : [eship, estation]};
          sinon.stub(ship, '_transfer_success');
          response_cb(response);
          sinon.assert.calledWith(ship._transfer_success, response, page);
        });
      });
    });
  });

  describe("#_transfer_failed", function(){
    var response = {error : {message : 'transfer error'}};

    it("shows error dialog", function(){
      sinon.spy(ship.dialog(), 'show_error_dialog');
      ship._transfer_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._transfer_failed(response);
      assert(ship.dialog().title).equals('Transfer Error');
    });

    it("appends error to dialog", function(){
      sinon.spy(ship.dialog(), 'append_error');
      ship._transfer_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'transfer error');
    });
  });

  describe("#_transfer_success", function(){
    var station;
    var nstation, nship, response;

    before(function(){
      station = new Omega.Station();
      ship.docked_at = station;

      var resource1 = {data : {material_id : 'silver'}};
      var resource2 = new Omega.Resource();

      nstation = new Omega.Station({resources : [resource1]});
      nship    = new Omega.Ship({docked_at : nstation,
                                 resources : [resource2]});
      response = {result : [nship, nstation]};

      sinon.stub(page.canvas, 'reload');
      sinon.stub(page.canvas.entity_container, 'refresh');
    });

    after(function(){
      page.canvas.reload.restore();
      page.canvas.entity_container.refresh.restore();
    });

    it("updates ship resources", function(){
      ship._transfer_success(response, page);
      assert(ship.resources).equals(nship.resources);
    });

    it("updates station resources", function(){
      ship._transfer_success(response, page);
      assert(station.resources.length).equals(1);
      assert(station.resources[0].material_id).equals('silver');
    });

    it("reloads ship in canvas scene", function(){
      ship._transfer_success(response, page);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      ship._transfer_success(response, page);
      sinon.spy(ship, 'update_gfx');
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });

    it("refreshes entity container", function(){
      ship._transfer_success(response, page);
      sinon.assert.called(page.canvas.entity_container.refresh);
    });
  });

  describe("#_mining_targets", function(){
    it("returns list of all asteroids in system within mining distance", function(){
      var ast1 = Omega.Gen.asteroid();
      var ast2 = Omega.Gen.asteroid();
      var ast3 = Omega.Gen.asteroid();
      ast1.location.set(0, 0, 0)
      ast2.location.set(0, 0, 0)
      ast3.location.set(1000, 1000, 1000)
      ship.mining_distance = 50;
      ship.solar_system = Omega.Gen.solar_system();
      sinon.stub(ship.solar_system, 'asteroids').returns([ast1, ast2, ast3]);
      assert(ship._mining_targets()).isSameAs([ast1, ast2]);
    });
  });

  describe("#_select_mining_target", function(){
    var ast1, ast2;

    before(function(){
      ast1 = Omega.Gen.asteroid();
      ast2 = Omega.Gen.asteroid();
      ship.solar_system = Omega.Gen.solar_system();
      sinon.stub(ship, '_mining_targets').returns([ast1, ast2]);
    });

    it("shows mining dialog", function(){
      sinon.stub(ship.dialog(), 'show_mining_dialog');
      ship._select_mining_target(page);
      sinon.assert.calledWith(ship.dialog().show_mining_dialog, page, ship);
    });

    it("refreshes mining targets", function(){
      sinon.stub(ship, '_refresh_mining_target');
      ship._select_mining_target(page);
      sinon.assert.calledWith(ship._refresh_mining_target, ast1, page);
      sinon.assert.calledWith(ship._refresh_mining_target, ast2, page);
    });
  });

  describe("#refresh_mining_target", function(){
    before(function(){
      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes cosmos::get_resources with target id", function(){
      var ast = Omega.Gen.asteroid();
      ship._refresh_mining_target(ast, page);
      sinon.assert.calledWith(page.node.http_invoke,
        'cosmos::get_resources', ast.id, sinon.match.func);
    });

    describe("cosmos::get_resource callback", function(){
      var ast, response_cb, resources, response;

      before(function(){
        ast = Omega.Gen.asteroid();
        ship._refresh_mining_target(ast, page);

        response_cb = page.node.http_invoke.omega_callback();
        resources   = [new Omega.Resource(), new Omega.Resource()];
        response    = {result : resources};
      });

      it("appends mining command for resources to dialog", function(){
        var append_cmd = sinon.spy(ship.dialog(), 'append_mining_cmd');
        response_cb(response);
        sinon.assert.calledWith(append_cmd, page, ship, resources[0], ast);
        sinon.assert.calledWith(append_cmd, page, ship, resources[1], ast);
      });
    });
  });

  describe("_start_mining", function(){
    var resource, asteroid, evnt;

    before(function(){
      resource = new Omega.Resource({id : 'res1'});
      asteroid = Omega.Gen.asteroid();

      evnt = $.Event('click');
      evnt.currentTarget = $('<span/>');
      evnt.currentTarget.data('resource', resource);
      evnt.currentTarget.data('asteroid', asteroid);

      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::start_mining with command resource", function(){
      ship._start_mining(page, evnt);
      sinon.assert.calledWith(page.node.http_invoke,
        'manufactured::start_mining', ship.id, resource.id,
        sinon.match.func);
    });

    describe("on manufactured::start_mining response", function(){
      var response_cb;

      before(function(){
        ship._start_mining(page, evnt);
        response_cb = page.node.http_invoke.omega_callback();
      });

      describe("on failure", function(){
        it("invokes _mining_failed", function(){
          var response = {error : {message : 'mining error'}};
          sinon.spy(ship, '_mining_failed');
          response_cb(response);
          sinon.assert.calledWith(ship._mining_failed, response);
        });
      });

      describe("on success", function(){
        it("invokes _mining_success", function(){
          var response = {result : Omega.Gen.ship()};
          sinon.spy(ship, '_mining_success');
          response_cb(response);
          sinon.assert.calledWith(ship._mining_success, response,
                                  page, resource, asteroid);
        });
      });
    });
  });

  describe("#_mining_failed", function(){
    var response = {error : {message : 'mining error'}};

    it("shows error dialog", function(){
      sinon.stub(ship.dialog(), 'show_error_dialog');
      ship._mining_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._mining_failed(response);
      assert(ship.dialog().title).equals('Mining Error');
    });

    it("appends error to dialog", function(){
      sinon.stub(ship.dialog(), 'append_error');
      ship._mining_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'mining error');
    });
  });

  describe("#_mining_success", function(){
    var ship, response, resource, asteroid;
    before(function(){
      resource = new Omega.Resource({id : 'res1'});
      asteroid = new Omega.Asteroid({});
      ship     = new Omega.Ship({mining: resource});
      response = {result : ship};

      sinon.stub(page.canvas, 'reload');
    });

    after(function(){
      page.canvas.reload.restore();
    });

    it("hides the dialog", function(){
      sinon.stub(ship.dialog(), 'hide');
      ship._mining_success(response, page, resource, asteroid);
      sinon.assert.called(ship.dialog().hide);
    });

    it("updates ship mining target", function(){
      ship._mining_success(response, page, resource, asteroid);
      assert(ship.mining).equals(ship.mining);
    });

    it("reloads ship in canvas scene", function(){
      ship._mining_success(response, page, resource, asteroid);
      sinon.assert.calledWith(page.canvas.reload, ship);
    });

    it("updates ship graphics", function(){
      ship._mining_success(response, page, resource, asteroid);
      sinon.spy(ship, 'update_gfx');
      page.canvas.reload.omega_callback()();
      sinon.assert.called(ship.update_gfx);
    });
  });
});});
