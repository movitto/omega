/// Currently testing through use in CommandDialog Mixin
pavlov.specify("Omega.UI.CommandDialog", function(){
describe("Omega.UI.CommandDialog", function(){
  var dialog, page, station;

  before(function(){
    page   = new Omega.Pages.Test({node : new Omega.Node()});
    dialog = new Omega.UI.CommandDialog();
    station = Omega.Gen.station();
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  describe("#show_construction_dialog", function(){
    it("sets dialog title", function(){
      dialog.show_construction_dialog(page, station);
      assert(dialog.title).equals('Construct Entity');
    });

    it("shows construction dialog", function(){
      sinon.stub(dialog, 'show');
      dialog.show_construction_dialog(page, station);
      assert(dialog.div_id).equals('#set_construction_params_dialog');
      sinon.assert.called(dialog.show);
    });

    it("generates new entity id", function(){
      dialog.show_construction_dialog(page, station);
      assert($('#construction_entity_id').val()).isNotEqualTo('');
    });

    it("handles changes to entity class", function(){
      assert($('#construction_entity_class')).doesNotHandle('change');
      dialog.show_construction_dialog(page, station);
      assert($('#construction_entity_class')).handles('change');
    });

    describe("changed entity class", function(){
      it("updates ship type selection from configured class keys", function(){
        dialog.show_construction_dialog(page, station);
        $('#construction_entity_class')[0].selectedIndex = 0; /// ship
        $('#construction_entity_class').trigger('change');

        var config_types = Object.keys(Omega.Config.resources.ships);
        var types = $('#construction_entity_type option');
        assert(types.length).equals(config_types.length)
        for(var s = 0; s < config_types.length; s++)
          assert($(types[s]).val()).equals(config_types[s]);
      });

      it("updates station type selection from configured class keys", function(){
        dialog.show_construction_dialog(page, station);
        $('#construction_entity_class')[0].selectedIndex = 1; /// station
        $('#construction_entity_class').trigger('change');

        var config_types = Object.keys(Omega.Config.resources.stations);
        var types = $('#construction_entity_type option');
        assert(types.length).equals(config_types.length)
        for(var s = 0; s < config_types.length; s++)
          assert($(types[s]).val()).equals(config_types[s]);
      });
    });

    it("handles construct command click", function(){
      assert($('#command_construct')).doesNotHandle('click');
      dialog.show_construction_dialog(page, station);
      assert($('#command_construct')).handles('click');
    });

    describe("construction command clicked", function(){
      it("constructs entity with specified params", function(){
        $('#construction_entity_class')[0].selectedIndex = 1;
        $('#construction_entity_class').trigger('change');
        $('#construction_entity_type')[0].selectedIndex = 0;

        sinon.stub(station, '_construct');
        dialog.show_construction_dialog(page, station);

        $('#construction_entity_id').val('eid');
        $('#command_construct').trigger('click');

        var expected = ['entity_type', 'Station', 'type', 'manufacturing', 'id', 'eid'];
        sinon.assert.calledWith(station._construct, page, expected);
      });

      it("hides construction dialog", function(){
        sinon.stub(station, '_construct'); /// stub out construct
        sinon.spy(dialog, 'hide');
        dialog.show_construction_dialog(page, station);
        $('#command_construct').trigger('click');
        sinon.assert.called(dialog.hide);
      });
    });
  });
});});
