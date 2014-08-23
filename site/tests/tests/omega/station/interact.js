// Test mixin usage through ship
pavlov.specify("Omega.StationInteraction", function(){
describe("Omega.StationInteraction", function(){
  describe("#construct", function(){
    var station, page;

    before(function(){
      station = Omega.Gen.station();

      page = new Omega.Pages.Test();
      sinon.stub(page.node, 'http_invoke');
      sinon.stub(page.audio_controls, 'play');
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
        before(function(){
          sinon.stub(station.dialog(), 'show_error_dialog');
          sinon.spy(station.dialog(), 'append_error');
        });

        after(function(){
          station.dialog().show_error_dialog.restore();
          station.dialog().append_error.restore();
        });

        it("sets command dialog title", function(){
          handler(error_response);
          assert(station.dialog().title).equals('Construction Error');
        });

        it("shows command dialog", function(){
          handler(error_response);
          sinon.assert.called(station.dialog().show_error_dialog);
          assert(station.dialog().component()).isVisible();
        });

        it("appends error to command dialog", function(){
          handler(error_response);
          sinon.assert.calledWith(station.dialog().append_error, 'construct_error');
          assert($('#command_error').html()).equals('construct_error');
        });
      });

      describe("successful response", function(){
        it("sets constructing true", function(){
          handler(success_response);
          assert(station._constructing).isTrue();
        });

        it("plays 'started' construction audio", function(){
          handler(success_response);
          sinon.assert.calledWith(page.audio_controls.play,
                                  station.construction_audio, 'started');
        });
      });
    });
  });

});});
