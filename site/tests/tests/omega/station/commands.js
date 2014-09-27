// Test mixin usage through ship
pavlov.specify("Omega.StationCommands", function(){
describe("Omega.StationCommands", function(){
  describe("#retrieve_details", function(){
    var station, details_cb, page;

    before(function(){
      station = Omega.Gen.station({id: 'station1', user_id : 'user1'});
      station.location.set(99, -2, 100);
      station.resources = [{quantity : 50, material_id : 'gold'},
                           {quantity : 25, material_id : 'ruby'}];
      details_cb = sinon.spy();

      page = new Omega.Pages.Test();
      page.session = new Omega.Session({user_id : 'user1'});
    });

    it("invokes details cb with station id, location, and resources", function(){
      var text = ['Station: station1',
                  '@ 9.90e+1/-2.00e+0/1.00e+2',
                  'Resources: 50 of gold 25 of ruby'];

      station.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0].text()).equals(text[0]);
      assert(details[1].text()).equals(text[1]);
      assert(details[2].text()).equals(text[2]);
    });

    it("invokes details cb with station commands", function(){
      station.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];

      var cmd = details[3].children()[0];
      assert(cmd.id).equals('station_construct_station1');
      assert(cmd.className).equals('station_construct details_command');
      assert($(cmd).text()).equals('construct');
    });

    it("sets station in construction command data", function(){
      station.retrieve_details(page, details_cb);
      $('#qunit-fixture').append(details_cb.getCall(0).args[0]);
      assert($('#station_construct_station1').data('station')).equals(station);
    });

    it("handles construction command click event", function(){
      station.retrieve_details(page, details_cb);
      var construct = details_cb.getCall(0).args[0][3].children()[0];
      assert($(construct)).handles('click');
    });

    describe('construction command click', function(){
      it('invokes set_construction_params', function(){
        sinon.stub(station, '_set_construction_params');
        station.retrieve_details(page, details_cb);
        var construct = details_cb.getCall(0).args[0][3].children()[0];
        $(construct).click();
        sinon.assert.called(station._set_construction_params);
      });
    });
  });

  describe("#refresh_details", function(){
    var station, details_cb, page;

    before(function(){
      station = Omega.Gen.station();
      details_cb = sinon.spy();
      page = new Omega.Pages.Test();

      station.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      $('#qunit-fixture').append(details);
    });

    it("refreshes station location details", function(){
      var element = '<div>foo</div>';
      sinon.stub(station, '_loc_details').returns($(element));
      station.refresh_details();
      assert($('#station_loc').html()).equals('foo');
    });

    it("refreshes station resource details", function(){
      var element = '<div>foo</div>';
      sinon.stub(station, '_resource_details').returns($(element));
      station.refresh_details();
      assert($('#station_resources').html()).equals('foo');
    });
  });

  describe("#refresh_cmds", function(){
    var station, details_cb, page;

    before(function(){
      station = Omega.Gen.station();
      details_cb = sinon.spy();
      page = new Omega.Pages.Test();

      station.retrieve_details(page, details_cb);
      var details = details_cb.getCall(0).args[0];
      $('#qunit-fixture').append(details);
    });

    it("refreshes station commands", function(){
      var element = '<div>foo</div>';
      sinon.stub(station, '_command_details').returns($(element));
      station.refresh_cmds(page);
      assert($('#station_cmds').html()).equals(element);
      sinon.assert.calledWith(station._command_details, page);
    });
  });
});});
