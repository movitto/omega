/// Currently testing through use in CommandDialog Mixin
pavlov.specify("Omega.UI.CommandDialog", function(){
describe("Omega.UI.CommandDialog", function(){
  var dialog, page;

  before(function(){
    page   = new Omega.Pages.Test({node : new Omega.Node()});
    dialog = new Omega.UI.CommandDialog();
  });

  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe("#show_docking_dialog", function(){
    var ship, stations;

    before(function(){
      ship = new Omega.Ship({id : 'ship1'});
      var tstation1 = new Omega.Station({id : 'tstation1' });
      var tstation2 = new Omega.Station({id : 'tstation2' });
      stations = [tstation1, tstation2];
    });

    it("sets dialog title", function(){
      dialog.show_docking_dialog(page, ship, stations);
      assert(dialog.title).equals('Dock Ship');
    });

    it("shows select docking station dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_docking_dialog(page, ship, stations);
      assert(dialog.div_id).equals('#select_docking_station_dialog');
      sinon.assert.called(show);
    });

    it("sets docking entity id", function(){
      dialog.show_docking_dialog(page, ship, stations);
      assert($('#dock_id').html()).equals('Dock ship1 at:');
    });

    it("adds docking commands for stations to dialog", function(){
      dialog.show_docking_dialog(page, ship, stations);
      var cmds = $('#dock_stations').children();
      assert(cmds.length).equals(2);
      assert(cmds[0].id).equals('dock_tstation1');
      assert(cmds[1].id).equals('dock_tstation2');
      assert(cmds[0].className).contains('cmd_dock');
      assert(cmds[0].className).contains('dialog_cmd');
      assert(cmds[1].className).contains('cmd_dock');
      assert(cmds[1].className).contains('dialog_cmd');
      assert(cmds[0].innerHTML).equals('tstation1');
      assert(cmds[1].innerHTML).equals('tstation2');
    });

    it("sets entity on docking commands", function(){
      dialog.show_docking_dialog(page, ship, stations);
      var cmds = $('#dock_stations').children();
      assert($(cmds[0]).data('entity')).equals(ship);
      assert($(cmds[1]).data('entity')).equals(ship);
    });

    it("sets station on docking commands", function(){
      dialog.show_docking_dialog(page, ship, stations);
      var cmds = $('#dock_stations').children();
      assert($(cmds[0]).data('station')).equals(stations[0]);
      assert($(cmds[1]).data('station')).equals(stations[1]);
    });

    describe("on docking command click", function(){
      before(function(){
        dialog.show_docking_dialog(page, ship, stations);
      });

      it("invokes entity._dock with event", function(){
        var dock = sinon.spy(ship, '_dock');
        $('#dock_tstation1').click();
        sinon.assert.calledWith(dock, page);
        var evnt = dock.getCall(0).args[1];
        assert($(evnt.currentTarget).data('entity')).equals(ship);
        assert($(evnt.currentTarget).data('station')).equals(stations[0]);
      });
    });
  });
});});
