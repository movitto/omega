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

  describe('#append_error', function(){
    it('appends error to dialog', function(){
      dialog.append_error('command error');
      assert($('#command_error').html()).equals('command error');
    });
  });

  describe("#show_error_dialog", function(){
    it("shows the command_dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_error_dialog();
      assert(dialog.div_id).equals('#command_dialog');
      sinon.assert.called(show);
    });
  });

  describe("#show_destination_selection_dialog", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({id : 'ship1',
                             location : new Omega.Location({x:10.12,y:10.889,z:-20.1})});
    });

    it("sets dialog title", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert(dialog.title).equals('Move Ship');
    });

    it("shows select destination dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_destination_selection_dialog(page, ship);
      assert(dialog.div_id).equals('#select_destination_dialog');
      sinon.assert.called(show);
    });

    it("sets dest entity id", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_id').html()).equals(ship.id);
    });

    it("sets current x coordinate as dest x", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_x').val()).equals('10.12');
    });

    it("sets current y coordinate as dest y", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_y').val()).equals('10.89');
    });

    it("sets current z coordinate as dest z", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_z').val()).equals('-20.1');
    });

    it("wires up move command button", function(){
      assert($('#command_move')).doesNotHandle('click');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#command_move')).handles('click');
    });

    describe("on move command button click", function(){
      before(function(){
        dialog.show_destination_selection_dialog(page, ship);
      });

      it("invokes entity._move with coordinates retrieved from inputs", function(){
        $('#dest_x').val('500.188');
        $('#dest_y').val('0.99');
        $('#dest_z').val('-42');

        var move = sinon.spy(ship, '_move');
        $('#command_move').click();
        sinon.assert.calledWith(move, page, '500.188', '0.99', '-42');
      });
    });
  });


  describe("#show_attack_dialog", function(){
    var ship, targets;

    before(function(){
      ship = new Omega.Ship({id : 'ship1'});
      var tship1 = new Omega.Ship({id : 'tship1' });
      var tship2 = new Omega.Ship({id : 'tship2' });
      targets = [tship1, tship2];
    });

    it("sets dialog title", function(){
      dialog.show_attack_dialog(page, ship, targets);
      assert(dialog.title).equals('Launch Attack');
    });

    it("shows select attack target dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_attack_dialog(page, ship, targets);
      assert(dialog.div_id).equals('#select_attack_target_dialog');
      sinon.assert.called(show);
    });

    it("sets attack entity id", function(){
      dialog.show_attack_dialog(page, ship, targets);
      assert($('#attack_id').html()).equals('Select ship1 target');
    });

    it("adds attack commands for targets to dialog", function(){
      dialog.show_attack_dialog(page, ship, targets);
      var cmds = $('#attack_targets').children();
      assert(cmds.length).equals(2);
      assert(cmds[0].id).equals('attack_tship1');
      assert(cmds[1].id).equals('attack_tship2');
      assert(cmds[0].className).contains('cmd_attack');
      assert(cmds[0].className).contains('dialog_cmd');
      assert(cmds[1].className).contains('cmd_attack');
      assert(cmds[1].className).contains('dialog_cmd');
      assert(cmds[0].innerHTML).equals('tship1');
      assert(cmds[1].innerHTML).equals('tship2');
    });

    it("sets entity on attack commands", function(){
      dialog.show_attack_dialog(page, ship, targets);
      var cmds = $('#attack_targets').children();
      assert($(cmds[0]).data('entity')).equals(ship);
      assert($(cmds[1]).data('entity')).equals(ship);
    });

    it("sets target on attack commands", function(){
      dialog.show_attack_dialog(page, ship, targets);
      var cmds = $('#attack_targets').children();
      assert($(cmds[0]).data('target')).equals(targets[0]);
      assert($(cmds[1]).data('target')).equals(targets[1]);
    });
  
    describe("on attack command click", function(){
      before(function(){
        dialog.show_attack_dialog(page, ship, targets);
      });

      it("invokes entity._start_attacking with command target", function(){
        var start_attacking = sinon.spy(ship, '_start_attacking');
        $('#attack_tship1').click();
        sinon.assert.calledWith(start_attacking, page);
        var evnt = start_attacking.getCall(0).args[1];
        assert($(evnt.currentTarget).data('entity')).equals(ship);
        assert($(evnt.currentTarget).data('target')).equals(targets[0]);
      });
    });
  });

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

  describe("#show_mining_dialog", function(){
    var ship;

    before(function(){
      ship = new Omega.Ship({id : 'ship1'});
    });

    it("sets dialog title", function(){
      dialog.show_mining_dialog(page, ship);
      assert(dialog.title).equals('Start Mining');
    });

    it("shows select mining target dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_mining_dialog(page, ship);
      assert(dialog.div_id).equals('#select_mining_target_dialog');
      sinon.assert.called(show);
    });

    it("sets mining entity id", function(){
      dialog.show_mining_dialog(page, ship);
      assert($('#mining_id').html()).equals('Select resource to mine with ship1');
    });
  });

  describe("#append_mining_cmd", function(){
    var ship, resource;

    before(function(){
      ship = new Omega.Ship({id : 'ship1'});
      resource = new Omega.Resource({id : 'tres', material_id : 'ruby', quantity : 50 });
    });

    it("adds mining command for specified resource to dialog", function(){
      dialog.append_mining_cmd(page, ship, resource);
      var cmds = $('#mining_targets').children();
      assert(cmds.length).equals(1);
      assert(cmds[0].id).equals('mine_tres');
      assert(cmds[0].className).contains('cmd_mine');
      assert(cmds[0].className).contains('dialog_cmd');
      assert(cmds[0].innerHTML).equals('ruby (50)');

      dialog.append_mining_cmd(page, ship, resource);
      var cmds = $('#mining_targets').children();
      assert(cmds.length).equals(2);
    });

    it("sets entity on mining command", function(){
      dialog.append_mining_cmd(page, ship, resource);
      var cmds = $('#mining_targets').children();
      assert($(cmds[0]).data('entity')).equals(ship);
    });

    it("sets resource on mining command", function(){
      dialog.append_mining_cmd(page, ship, resource);
      var cmds = $('#mining_targets').children();
      assert($(cmds[0]).data('resource')).equals(resource);
    });

    describe("on mining command click", function(){
      before(function(){
        dialog.append_mining_cmd(page, ship, resource);
      });

      it("invokes entity._start_mining with event", function(){
        var start_mining = sinon.spy(ship, '_start_mining');
        $('#mine_tres').click();
        sinon.assert.calledWith(start_mining, page);
        var evnt = start_mining.getCall(0).args[1];
        assert($(evnt.currentTarget).data('entity')).equals(ship);
        assert($(evnt.currentTarget).data('resource')).equals(resource);
      });
    });
  });
});});

pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  describe("callbacks", function(){
    describe("#motel_event", function(){
      it("updates entity location");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#resource_collected", function(){
      it("updates entity mining target");
      it("updates entity resources");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#mining_stopped", function(){
      it("clears entity mining target");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#attacked", function(){
      it("updates entity attacking target");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#attacked_stop", function(){
      it("clears entity attacking target");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#defended", function(){
      it("updates entity hp and shield level");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#defended_stop", function(){
      it("updates entity hp and shield level");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#destroyed_by", function(){
      it("clears entity attacking target");
      it("sets entity hp and shield level to 0");
      it("reloads entity in scene");
      it("updates entity gfx");
      it("refreshes entity container");
    });

    describe("#construction_complete", function(){
      it("retrieves constructed entity");
      it("processes constructed entity");
      it("adds constructed entity to canvas scene");
    });

    //describe("#partial_construction", function(){
    //});
  });

  describe("#track", function(){
    it("clears node event handlers for event");
    it("adds new node event handler for event");
    describe("event occurred", function(){
      describe("motel event", function(){
        it("invokes motel_event callback");
      });
      describe("resource collected event", function(){
        it("invokes resource_collected callback")
      });
      describe("mining stopped event", function(){
        it("invokes mining_stopped callback")
      });
      describe("attacked event", function(){
        it("invokes attacked callback")
      });
      describe("attacked stop event", function(){
        it("invokes attacked_stop callback")
      });
      describe("defended event", function(){
        it("invokes defended callback")
      });
      describe("defended stop event", function(){
        it("invokes defended_stop callback")
      });
      describe("destroyed_by event", function(){
        it("invokes destroyed_by callback")
      });
      describe("construction_complete event", function(){
        it("invokes construction_complete callback")
      });
      //describe("partial_construction event", function(){
      //});
    });
  })
});});
