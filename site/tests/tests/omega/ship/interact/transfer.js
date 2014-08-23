// Test mixin usage through ship
pavlov.specify("Omega.ShipTransferInteractions", function(){
describe("Omega.ShipTransferInteractions", function(){
  var ship, page;

  before(function(){
    ship = Omega.Gen.ship();
    ship.location.set(0,0,0);
    ship.init_gfx()
    page = new Omega.Pages.Test();
  });

  describe("#_transfer", function(){
    before(function(){
      ship.docked_at_id = 'station1';

      var res1 = new Omega.Resource();
      var res2 = new Omega.Resource();
      ship.resources = [res1, res2];

      sinon.stub(page.node, 'http_invoke');
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

        describe("all resources transfered", function(){
          it("invokes _transfer_complete", function(){
            var estation = Omega.Gen.station();
            var eship = Omega.Gen.ship();
            var response = {result : [eship, estation]};
            sinon.stub(ship, '_transfer_success'); // stub out transfer_success
            sinon.stub(ship, '_transfer_complete');
            response_cb(response);
            sinon.assert.notCalled(ship._transfer_complete);
            response_cb(response);
            sinon.assert.calledWith(ship._transfer_complete, page);
          });
        });
      });
    });
  });

  describe("#_transfer_failed", function(){
    var response = {error : {message : 'transfer error'}};

    before(function(){
      sinon.spy(ship.dialog(), 'show_error_dialog');
      sinon.spy(ship.dialog(), 'append_error');
    });

    after(function(){
      ship.dialog().show_error_dialog.restore();
      ship.dialog().append_error.restore();
    });

    it("shows error dialog", function(){
      ship._transfer_failed(response);
      sinon.assert.called(ship.dialog().show_error_dialog);
    });

    it("sets dialog title", function(){
      ship._transfer_failed(response);
      assert(ship.dialog().title).equals('Transfer Error');
    });

    it("appends error to dialog", function(){
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

    it("refreshes ship details", function(){
      sinon.stub(ship, 'refresh_details');
      ship._transfer_success(response, page);
      sinon.assert.called(ship.refresh_details);
    });
  });

  describe("#_transfer_complete", function(){
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

      sinon.stub(page.audio_controls, 'play');
    });

    it("plays confirmation effect audio", function(){
      ship._transfer_complete(page);
      sinon.assert.calledWith(page.audio_controls.play,
                              page.audio_controls.effects.confirmation);
    });
  });
});});
