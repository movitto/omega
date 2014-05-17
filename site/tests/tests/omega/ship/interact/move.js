// Test mixin usage through ship
pavlov.specify("Omega.ShipMovementInteractions", function(){
describe("Omega.ShipMovementInteractions", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    ship.init_gfx(Omega.Config)
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
      sinon.stub(ship.dialog(), 'show_destination_selection_dialog');
      sinon.stub(page.canvas.root, 'asteroids').returns([asteroid1]);
      sinon.stub(page.canvas.root, 'jump_gates').returns([jg1]);
    });

    after(function(){
      page.restore_canvas_root();
      ship.dialog().show_destination_selection_dialog.restore();
    });

    it("shows select destination dialog", function(){
      ship._select_destination(page);
      sinon.assert.calledWith(ship.dialog().show_destination_selection_dialog,
                              page, ship, sinon.match.object);
    });

    it("retrieves entities to render in destination select box", function(){
      ship._select_destination(page);

      var entities =
        ship.dialog().show_destination_selection_dialog.getCall(0).args[2];
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

    before(function(){
      sinon.spy(ship.dialog(), 'show_error_dialog');
      sinon.spy(ship.dialog(), 'append_error');
      sinon.spy(ship.dialog(), 'clear_errors');
    });

    after(function(){
      ship.dialog().show_error_dialog.restore();
      ship.dialog().append_error.restore();
      ship.dialog().clear_errors.restore();
    });

    it("clears error dialog", function(){
      ship._move_failed(response);
      sinon.assert.called(ship.dialog().clear_errors);
    });

    it("shows error dialog", function(){
      ship._move_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._move_failed(response);
      assert(ship.dialog().title).equals('Movement Error');
    });

    it("appends error to dialog", function(){
      ship._move_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'move err');
    });
  });

  describe("#_move_success", function(){
    var nship, response;

    before(function(){
      nship = Omega.Gen.ship();
      response = {result : nship};
      sinon.stub(ship.dialog(), 'hide');
      sinon.stub(page.canvas, 'reload');
      sinon.stub(page.audio_controls, 'play');
    })

    after(function(){
      ship.dialog().hide.restore();
      page.canvas.reload.restore();
      page.audio_controls.play.restore();
    });

    it("hides the dialog", function(){
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

    it("plays confirmation audio", function(){
      ship._move_success(response, page);
      sinon.assert.calledWith(page.audio_controls.play,
                              page.audio_controls.effects.confirmation);
    });

    it("starting playing ship movement audio", function(){
      ship._move_success(response, page);
      sinon.assert.calledWith(page.audio_controls.play,
                              ship.movement_audio);
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

    before(function(){
      sinon.stub(ship.dialog(), 'clear_errors');
      sinon.stub(ship.dialog(), 'show_error_dialog');
      sinon.stub(ship.dialog(), 'append_error');
    });

    after(function(){
      ship.dialog().clear_errors.restore();
      ship.dialog().show_error_dialog.restore();
      ship.dialog().append_error.restore();
    });

    it("clears error dialog", function(){
      ship._follow_failed(response);
      sinon.assert.called(ship.dialog().clear_errors);
    });

    it("shows error dialog", function(){
      ship._follow_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._follow_failed(response);
      assert(ship.dialog().title).equals('Movement Error');
    });

    it("appends error to dialog", function(){
      ship._follow_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'follow err');
    });
  });

  describe("#_follow_success", function(){
    var nship, response;

    before(function(){
      nship = Omega.Gen.ship();
      response = {result : nship};
      sinon.stub(ship.dialog(), 'hide');
      sinon.stub(page.canvas, 'reload');
    })

    after(function(){
      ship.dialog().hide.restore();
      page.canvas.reload.restore();
    });

    it("hides the dialog", function(){
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
});});
