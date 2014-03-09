// Test mixin usage through ship
pavlov.specify("Omega.StationInteraction", function(){
describe("Omega.StationInteraction", function(){
  describe("#construct", function(){
    var station, page;

    before(function(){
      station = Omega.Gen.station();

      page = Omega.Test.Page();
      sinon.stub(page.node, 'http_invoke');
    });

    after(function(){
      page.node.http_invoke.restore();
    });

    it("invokes manufactured::construct_entity", function(){
      station._construct(page);
      sinon.assert.calledWith(page.node.http_invoke, 'manufactured::construct_entity',
                  station.id, 'entity_type', 'Ship', 'type', 'mining', 'id');
      /// TODO match uuid
    });

    describe("on manufactured::construct_entity response", function(){
      var ship, station2, system;
      var handler, error_response, success_response;

      before(function(){
        station._construct(page);
        handler = page.node.http_invoke.omega_callback();

        system  = new Omega.SolarSystem({id : 'system1'});
        ship    = new Omega.Ship({parent_id : 'system1'});
        station2 = new Omega.Station({resources :
                    [{quantity : 5, material_id : 'diamond'}]});

        error_response = {error : {message : "construct_error"}};
        success_response = {result : [station2, ship]};
      });

      after(function(){
        Omega.UI.Dialog.remove();
      });

      describe("error during command", function(){
        it("sets command dialog title", function(){
          handler(error_response);
          assert(station.dialog().title).equals('Construction Error');
        });

        it("shows command dialog", function(){
          var show = sinon.spy(station.dialog(), 'show_error_dialog');
          handler(error_response);
          sinon.assert.called(show);
          assert(station.dialog().component()).isVisible();
        });

        it("appends error to command dialog", function(){
          var append_error = sinon.spy(station.dialog(), 'append_error');
          handler(error_response);
          sinon.assert.calledWith(append_error, 'construct_error');
          assert($('#command_error').html()).equals('construct_error');
        });
      });
    });
  });

});});
