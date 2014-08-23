// Test mixin usage through ship
pavlov.specify("Omega.ShipMiningInteractions", function(){
describe("Omega.ShipMiningInteractions", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    ship.init_gfx()
    page = new Omega.Pages.Test();
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

        sinon.stub(page.canvas, 'reload'); // stub out canvas reload
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

    before(function(){
      sinon.stub(ship.dialog(), 'show_error_dialog');
      sinon.spy(ship.dialog(), 'append_error');
    });

    after(function(){
      ship.dialog().show_error_dialog.restore();
      ship.dialog().append_error.restore();
    });

    it("shows error dialog", function(){
      ship._mining_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._mining_failed(response);
      assert(ship.dialog().title).equals('Mining Error');
    });

    it("appends error to dialog", function(){
      ship._mining_failed(response);
      sinon.assert.calledWith(ship.dialog().append_error, 'mining error');
    });
  });

  describe("#_mining_success", function(){
    var ship, response, resource, asteroid;
    before(function(){
      resource = new Omega.Resource({id : 'res1'});
      asteroid = new Omega.Asteroid({});
      ship     = Omega.Gen.ship({type: 'mining', mining: resource});
      response = {result : ship};

      ship.init_gfx();
      sinon.stub(ship.dialog(), 'hide');
      sinon.stub(page.canvas, 'reload');
      sinon.stub(page.audio_controls, 'play');
    });

    after(function(){
      ship.dialog().hide.restore();
    });

    it("hides the dialog", function(){
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

    it("plays ship mining audio effect", function(){
      ship._mining_success(response, page, resource, asteroid);
      sinon.assert.calledWith(page.audio_controls.play, ship.mining_audio);
    });
  });
});});
