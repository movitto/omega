// Test mixin usage through ship
pavlov.specify("Omega.ShipDockInteractions", function(){
describe("Omega.ShipDockInteractions", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    page = Omega.Test.Page();
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
});});
