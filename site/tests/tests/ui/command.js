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

  describe("#clear_errors", function(){
    it("clears errors from dialog", function(){
      $('#command_error').html('foobar');
      dialog.clear_errors();
      assert($('#command_error').html()).equals('');
    })
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
    var ship, dests,
        dstation;

    before(function(){
      ship = new Omega.Ship({id : 'ship1',
                             location : new Omega.Location({x:10.12,y:10.889,z:-20.1})});

      dstation = new Omega.Station({id : 'st1', location : new Omega.Location({x:50,y:-52,z:61})})
      dests = {
        stations : [dstation]
      };
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
      assert($('#dest_id').html()).equals('Move ' + ship.id + ' to:');
    });

    it("hides dest and coords selection sections", function(){
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_selection_section')).isHidden();
      assert($('#coords_selection_section')).isHidden();
    });

    it("wires up select dest section click handler", function(){
      assert($('#select_destination')).doesNotHandle('click');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#select_destination')).handles('click');
    });

    it("wires up select coords section click handler", function(){
      assert($('#select_coordinates')).doesNotHandle('click');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#select_coordinates')).handles('click');
    })

    it("adds specified destinations to dest selection box", function(){
      assert($('#dest_selection').children().length).equals(0);
      dialog.show_destination_selection_dialog(page, ship, dests);

      var entities = $('#dest_selection').children();
      assert(entities.length).equals(2);
      assert($(entities[0]).text()).equals('');
      assert($(entities[1]).data('id')).equals(dstation.id);
      assert($(entities[1]).text()).equals('station: ' + dstation.id);
      assert($(entities[1]).data('location')).isSameAs(dstation.location);
    });

    it("wires up destination select box option change", function(){
      dialog.show_destination_selection_dialog(page, ship, dests);
      var entity = $('#dest_selection');
      assert(entity).handles('change');
    });

    describe("on destination selection", function(){
      it("invokes entity._move w/ coordinates", function(){
        var move = sinon.stub(ship, '_move');

        dialog.show_destination_selection_dialog(page, ship, dests);
        var entity = $("#dest_selection");
        entity[0].selectedIndex = 1;

        entity.trigger('change');
        var loc = $(entity.children()[1]).data('location');
        var offset = Omega.Config.movement_offset;

        sinon.assert.calledWith(move, page);
        var args = move.getCall(0).args;
        var validate = [args[1] - loc.x,
                        args[2] - loc.y,
                        args[3] - loc.z];
        validate.forEach(function(dist){
          assert(dist).isLessThan(offset.max);
          assert(dist).isGreaterThan(offset.min);
        });
      });
    })

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

    it("wires up dest field enter keypress events", function(){
      assert($('#dest_x')).doesNotHandle('keypress');
      assert($('#dest_y')).doesNotHandle('keypress');
      assert($('#dest_z')).doesNotHandle('keypress');
      dialog.show_destination_selection_dialog(page, ship);
      assert($('#dest_x')).handles('keypress');
      assert($('#dest_y')).handles('keypress');
      assert($('#dest_z')).handles('keypress');
    });

    describe("on dest field enter keypress", function(){
      before(function(){
        dialog.show_destination_selection_dialog(page, ship);
      });

      it("invokes entity._move with coordinates from inputs", function(){
        $('#dest_x').val('-188.9');
        $('#dest_y').val('-2.42');
        $('#dest_z').val('1');

        var move = sinon.spy(ship, '_move');
        $('#dest_x').trigger(jQuery.Event('keypress', {which : 13}));
        sinon.assert.calledWith(move, page, '-188.9', '-2.42', '1');
      });
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
    var ship, resource, ast;

    before(function(){
      ship = new Omega.Ship({id : 'ship1'});
      resource = new Omega.Resource({id : 'tres', material_id : 'ruby', quantity : 50 });
      ast = new Omega.Asteroid({id : 'ast1'});
    });

    it("adds mining command for specified resource to dialog", function(){
      dialog.append_mining_cmd(page, ship, resource, ast);
      var cmds = $('#mining_targets').children();
      assert(cmds.length).equals(1);
      assert(cmds[0].id).equals('mine_tres');
      assert(cmds[0].className).contains('cmd_mine');
      assert(cmds[0].className).contains('dialog_cmd');
      assert(cmds[0].innerHTML).equals('ruby (50)');

      dialog.append_mining_cmd(page, ship, resource, ast);
      var cmds = $('#mining_targets').children();
      assert(cmds.length).equals(2);
    });

    it("sets entity on mining command", function(){
      dialog.append_mining_cmd(page, ship, resource, ast);
      var cmds = $('#mining_targets').children();
      assert($(cmds[0]).data('entity')).equals(ship);
    });

    it("sets resource on mining command", function(){
      dialog.append_mining_cmd(page, ship, resource, ast);
      var cmds = $('#mining_targets').children();
      assert($(cmds[0]).data('resource')).equals(resource);
    });

    it("sets asteroid on mining command", function(){
      dialog.append_mining_cmd(page, ship, resource, ast);
      var cmds = $('#mining_targets').children();
      assert($(cmds[0]).data('asteroid')).equals(ast);
    });

    describe("on mining command click", function(){
      before(function(){
        dialog.append_mining_cmd(page, ship, resource, ast);
      });

      it("invokes entity._start_mining with event", function(){
        var start_mining = sinon.spy(ship, '_start_mining');
        $('#mine_tres').click();
        sinon.assert.calledWith(start_mining, page);
        var evnt = start_mining.getCall(0).args[1];
        assert($(evnt.currentTarget).data('entity')).equals(ship);
        assert($(evnt.currentTarget).data('resource')).equals(resource);
        assert($(evnt.currentTarget).data('asteroid')).equals(ast);
      });
    });
  });
});});

pavlov.specify("Omega.UI.CommandTracker", function(){
describe("Omega.UI.CommandTracker", function(){
  var page, tracker, canvas_reload, canvas_add;

  before(function(){
    var node = new Omega.Node();
    page = new Omega.Pages.Test({node : node,
                                 canvas : Omega.Test.Canvas()});
    page.canvas.set_scene_root(new Omega.SolarSystem({id : 'system1'}))
    tracker = new Omega.UI.CommandTracker({page : page});

    /// stub these out so we don't have to load gfx
    canvas_reload = sinon.stub(page.canvas, 'reload');
    canvas_add = sinon.stub(page.canvas, 'add');
  });

  after(function(){
    page.canvas.reload.restore();
    page.canvas.add.restore();
    if(page.canvas.entity_container.refresh.restore) page.canvas.entity_container.refresh.restore();
  });

  describe("callbacks", function(){
    describe("#motel_event", function(){
      var ship, eship, eargs;

      before(function(){
        ship  = new Omega.Ship({system_id : 'system1',
                                location  : new Omega.Location({id:42,x:0,y:0,z:0,
                                  movement_strategy : {json_class : 'Motel::MovementStrategies::Stopped'}})});
        eship = new Omega.Ship({location : new Omega.Location({id:42,x:1,y:1,z:1,
                                  movement_strategy : {json_class : 'Motel::MovementStrategies::Stopped'}})});
                                
        page.entities = [ship];
        eargs         = [eship.location];
      });

      it("updates entity location", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        assert(ship.location).isSameAs(eship.location);
      });

      describe("changing movement strategy", function(){
        it("sets entity.last_moved to null", function(){
          eship.location.movement_strategy.json_class = 'Motel::MovementStrategies::Linear'
          ship.last_moved = new Date();
          tracker._callbacks_motel_event('motel::on_movement', eargs);
          assert(ship.last_moved).isNull();
        })
      })

      describe("not changing movement strategy", function(){
        it("sets entity.last_moved to now", function(){
          ship.last_moved = null;
          tracker._callbacks_motel_event('motel::on_movement', eargs);
          assert(ship.last_moved).isSameAs(new Date());
        });
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_motel_event('motel::on_movement', eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      })

      it("reloads entity in scene", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.assert.calledWith(canvas_reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(ship, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });

      it("refreshes entity container", function(){
        var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
        tracker._callbacks_motel_event('motel::on_movement', eargs);
        sinon.assert.called(refresh);
      });
    });

    describe("#resource_collected", function(){
      var ship, eship, eargs;

      before(function(){
        var res  = new Omega.Resource({material_id : 'gold', quantity : 10});
        var eres = new Omega.Resource({material_id : 'gold', quantity : 50});
        var ast  = new Omega.Asteroid();

        ship  = new Omega.Ship({id: 'ship1', system_id : 'system1', resources : [res]});
        eship = new Omega.Ship({id: 'ship1', resources : [eres], mining: ast});
        page.entities = [ship];
        eargs         = ['resource_collected', eship, res, 40];
      });

      it("updates entity mining target", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        assert(ship.mining).equals(eship.mining);
      });

      it("updates entity resources", function(){
        var update_resources = sinon.spy(ship, '_update_resources');
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        assert(ship.resources).isSameAs(eship.resources);
        sinon.assert.called(update_resources);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      })

      it("reloads entity in scene", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(ship, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });

      it("refreshes entity container", function(){
        var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
        tracker._callbacks_resource_collected("manufactured::event_occurred", eargs);
        sinon.assert.called(refresh);
      });
    });

    describe("#mining_stopped", function(){
      var ship, eship, eargs;

      before(function(){
        var ast = new Omega.Asteroid();
        ship  = new Omega.Ship({id: 'ship1', system_id : 'system1', mining: ast});
        eship = new Omega.Ship({id: 'ship1'});

        var res = new Omega.Resource();

        page.entities = [ship];
        eargs         = ['mining_stopped', eship, res, 'cargo_full'];
      });

      after(function(){
        if(page.canvas.entity_container.refresh.restore) page.canvas.entity_container.refresh.restore();
      });

      it("clears entity mining target", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        assert(ship.mining).isNull();
      });

      it("clears entity mining asteroid", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        assert(ship.mining_asteroid).isNull();
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(ship, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });

      it("refreshes entity container", function(){
        var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
        tracker._callbacks_mining_stopped("manufactured::event_occurred", eargs);
        sinon.assert.called(refresh);
      });
    });

    describe("#attacked", function(){
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        tgt    = new Omega.Ship({id : 'target_ship' });
        etgt   = new Omega.Ship({id : 'target_ship' });
        ship   = new Omega.Ship({id: 'ship1', system_id : 'system1'});
        eship  = new Omega.Ship({id: 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        eargs         = ['attacked', eship, etgt];
      });

      it("updates entity attacking target", function(){
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        assert(ship.attacking).equals(tgt);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_attacked("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_attacked("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(ship, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });
    });

    describe("#attacked_stop", function(){
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        tgt    = new Omega.Ship({id : 'target_ship'});
        etgt   = new Omega.Ship({id : 'target_ship' });
        ship   = new Omega.Ship({id: 'ship1', system_id : 'system1' });
        eship  = new Omega.Ship({id: 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        eargs         = ['attacked', eship, etgt];
      });

      it("clears entity attacking target", function(){
        tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
        assert(ship.attacking).isNull();
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          ship.parent_id = 'system2';
          tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, ship, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_attacked_stop("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(ship, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });
    });

    describe("#defended", function(){
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        tgt    = new Omega.Ship({id : 'target_ship', system_id : 'system1' });
        etgt   = new Omega.Ship({id : 'target_ship', hp : 77, shield_level : 99 });
        ship   = new Omega.Ship({id: 'ship1'});
        eship  = new Omega.Ship({id: 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        page.canvas.entities = [tgt.id];
        eargs         = ['defended', etgt, eship];
      });

      after(function(){
        page.canvas.clear();
      });

      it("updates entity hp and shield level", function(){
        tracker._callbacks_defended("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(77);
        assert(tgt.shield_level).equals(99);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          tgt.parent_id = 'system2';
          tracker._callbacks_defended("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_defended("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, tgt, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_defended("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(tgt, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });
    });

    describe("#defended_stop", function(){
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        tgt    = new Omega.Ship({id : 'target_ship', system_id : 'system1' });
        etgt   = new Omega.Ship({id : 'target_ship', hp : 77, shield_level : 99 });
        ship   = new Omega.Ship({id: 'ship1'});
        eship  = new Omega.Ship({id: 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        page.canvas.entities = [tgt.id];
        eargs         = ['defended_stop', etgt, eship];
      });

      it("updates entity hp and shield level", function(){
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(77);
        assert(tgt.shield_level).equals(99);
      });

      describe("entity not in scene", function(){
        it("does not reload entity", function(){
          tgt.parent_id = 'system2';
          tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
          sinon.assert.notCalled(canvas_reload);
        });
      });

      it("reloads entity in scene", function(){
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, tgt, sinon.match.func);
      });

      it("updates entity gfx", function(){
        tracker._callbacks_defended_stop("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(tgt, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });
    });

    describe("#destroyed_by", function(){
      var tgt, etgt, ship, eship, eargs;

      before(function(){
        tgt    = new Omega.Ship({id : 'target_ship', system_id : 'system1' });
        etgt   = new Omega.Ship({id : 'target_ship' });
        ship   = new Omega.Ship({id : 'ship1', system_id : 'system1' });
        eship  = new Omega.Ship({id : 'ship1', attacking : etgt});

        page.entities = [ship, tgt];
        page.canvas.entities = [ship.id, tgt.id];
        eargs         = ['destroyed_by', etgt, eship];
      });

      after(function(){
        if(page.canvas.remove.restore) page.canvas.remove.restore();
      });

      it("clears entity attacking target", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        assert(ship.attacking).isNull();
      });

      it("sets entity hp and shield level to 0", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        assert(tgt.hp).equals(0);
        assert(tgt.shield_level).equals(0);
      });

      it("reloads attacker in scene", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_reload, ship, sinon.match.func);
      });

      it("updates attacker gfx", function(){
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        var reload_cb = canvas_reload.getCall(0).args[1];
        var update_gfx = sinon.stub(ship, 'update_gfx');
        reload_cb();
        sinon.assert.called(update_gfx);
      });


      it("updates defender gfx", function(){
        var update_gfx = sinon.stub(tgt, 'update_gfx');
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.called(update_gfx);
      });

      it("removes defender from scene", function(){
        var canvas_remove = sinon.stub(page.canvas, 'remove');
        tracker._callbacks_destroyed_by("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(canvas_remove, tgt);
      });
    });

    describe("#construction_complete", function(){
      var constructed, station, estation, eargs,
          get, process_entity, refresh_entity_container;

      before(function(){
        constructed = new Omega.Ship({id : 'constructed_ship' });
        station     = new Omega.Station({id : 'station1'});
        estation    = new Omega.Station({id : 'station1', resources : [{'material_id' : 'gold'}]});

        page.entities = [station, constructed];
        eargs         = ['construction_complete', estation, constructed];

        get = sinon.stub(Omega.Ship, 'get');
        process_entity = sinon.stub(page, 'process_entity');
        refresh_entity_container = sinon.stub(page.canvas.entity_container, 'refresh');
      });

      after(function(){
        if(page.canvas.entity_container.refresh.restore) page.canvas.entity_container.refresh.restore();
        if(Omega.Ship.get.restore) Omega.Ship.get.restore();
        page.process_entity.restore();
      });

      it("retrieves constructed entity", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(get, 'constructed_ship', page.node, sinon.match.func);
      });

      it("processes constructed entity", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        var get_cb = get.getCall(0).args[2];
        var retrieved = new Omega.Ship();
        get_cb(retrieved);
        sinon.assert.calledWith(process_entity, retrieved);
      });

      it("adds constructed entity to canvas scene", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        var get_cb = get.getCall(0).args[2];
        var retrieved = new Omega.Ship({system_id : 'system1'});
        get_cb(retrieved);
        sinon.assert.calledWith(canvas_add, retrieved);
      });

      it("updates station resources", function(){
        var update_resources = sinon.spy(station, '_update_resources');
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.called(update_resources);
        assert(estation.resources).isSameAs(estation.resources)
      });

      it("refreshes the entity container", function(){
        tracker._callbacks_construction_complete("manufactured::event_occurred", eargs);
        sinon.assert.calledWith(refresh_entity_container);
      });
    });

    //describe("#partial_construction", function(){
    //});

    describe("#system_jump", function(){
      var jumped, system, ejumped, estation,
          eargs, process_entity;

      before(function(){
        system  = new Omega.SolarSystem({id : 'sys1'});
        esystem = new Omega.SolarSystem({id : 'sys1'});
        nsys    = new Omega.SolarSystem({id : 'sys2'});
        psys    = new Omega.SolarSystem({id : 'sys2'});

        jumped = new Omega.Ship({id : 'sh1' });
        ejumped = new Omega.Ship({id : 'sh1',
                                  solar_system :  nsys,
                                  system_id : nsys.id});

        eargs = ['system_jump', ejumped, esystem];

        process_entity = sinon.stub(page, 'process_entity');
      });

      after(function(){
        process_entity.restore();
      });

      it("updates entity system", function(){
        page.entities = [jumped, psys];
        tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
        assert(page.entity(jumped.id).solar_system).equals(psys);
      });

      describe("entity does not exist locally", function(){
        it("stores entity in registry", function(){
          page.entities = [psys];
          tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
          assert(page.entity(jumped.id)).isNotNull();
        });
      });

      describe("entity in scene root", function(){
        before(function(){
          page.canvas.set_scene_root(psys);
        });

        it("processes_entity on page", function(){
          page.entities = [jumped, psys];
          tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
          sinon.assert.calledWith(process_entity, jumped);
        });

        it("adds entity to canvas", function(){
          page.entities = [jumped, psys];
          tracker._callbacks_system_jump("manufactured::event_occurred", eargs);
          sinon.assert.calledWith(canvas_add, jumped);
        });
      });
    });
  });

  describe("#_msg_received", function(){
    before(function(){
      page.entities = [];
    });

    describe("event occurred", function(){
      describe("motel event", function(){
        it("invokes motel_event callback", function(){
          var eargs = [{}];
          var motel_event = sinon.spy(tracker, '_callbacks_motel_event');
          tracker._msg_received('motel::on_rotation', eargs);
          sinon.assert.calledWith(motel_event, 'motel::on_rotation', eargs);
        });
      });

      describe("resource collected event", function(){
        it("invokes resource_collected callback", function(){
          var eargs = ['resource_collected', {}];
          var resource_collected = sinon.spy(tracker, '_callbacks_resource_collected');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(resource_collected, 'manufactured::event_occurred', eargs);
        });
      });

      describe("mining stopped event", function(){
        it("invokes mining_stopped callback", function(){
          var eargs = ['mining_stopped', {}];
          var mining_stopped = sinon.spy(tracker, '_callbacks_mining_stopped');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(mining_stopped, 'manufactured::event_occurred', eargs);
        });
      });

      describe("attacked event", function(){
        it("invokes attacked callback", function(){
          var eargs    = ['attacked', {}];
          var attacked = sinon.spy(tracker, '_callbacks_attacked');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(attacked, 'manufactured::event_occurred', eargs);
        });
      });

      describe("attacked stop event", function(){
        it("invokes attacked_stop callback", function(){
          var eargs = ['attacked_stop', {}];
          var attacked_stop = sinon.spy(tracker, '_callbacks_attacked_stop');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(attacked_stop, 'manufactured::event_occurred', eargs);
        });
      });

      describe("defended event", function(){
        it("invokes defended callback", function(){
          var eargs = ['defended', {}];
          var defended = sinon.spy(tracker, '_callbacks_defended');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(defended, 'manufactured::event_occurred', eargs);
        });
      });

      describe("defended stop event", function(){
        it("invokes defended_stop callback", function(){
          var eargs = ['defended_stop', {}];
          var defended_stop = sinon.spy(tracker, '_callbacks_defended_stop');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(defended_stop, 'manufactured::event_occurred', eargs);
        });
      });

      describe("destroyed_by event", function(){
        it("invokes destroyed_by callback", function(){
          var eargs = ['destroyed_by', {}];
          var destroyed_by = sinon.spy(tracker, '_callbacks_destroyed_by');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(destroyed_by, 'manufactured::event_occurred', eargs);
        });
      });

      describe("construction_complete event", function(){
        it("invokes construction_complete callback", function(){
          var eargs = ['construction_complete', {}];
          var construction_complete = sinon.stub(tracker, '_callbacks_construction_complete');
          tracker._msg_received('manufactured::event_occurred', eargs);
          sinon.assert.calledWith(construction_complete, 'manufactured::event_occurred', eargs);
        });
      });

      //describe("partial_construction event", function(){
      //});

      describe("system_jump event", function(){
        it("invokes system_jump callback", function(){
          var eargs = ['system_jump', {}]
          var system_jump = sinon.stub(tracker, '_callbacks_system_jump');
          tracker._msg_received('manufactured::event_occurred', eargs)
          sinon.assert.calledWith(system_jump, 'manufactured::event_occurred', eargs)
        });
      });
    });
  })

  describe("#track", function(){
    before(function(){
      page.entities = [];
    });

    describe("event handler already registered", function(){
      it("does nothing / just returns", function(){
        tracker.track("motel::on_rotation");
        assert(page.node._listeners['motel::on_rotation'].length).equals(1);
        tracker.track("motel::on_rotation");
        assert(page.node._listeners['motel::on_rotation'].length).equals(1);
      });
    });

    it("adds new node event handler for event", function(){
      var add_listener = sinon.spy(page.node, 'addEventListener');
      tracker.track("motel::on_rotation");
      sinon.assert.calledWith(add_listener, 'motel::on_rotation', sinon.match.func);
    });

    describe("on event", function(){
      it("invokes _msg_received", function(){
        var msg_received = sinon.spy(tracker, "_msg_received");
        tracker.track("motel::on_rotation");
        var handler = page.node._listeners['motel::on_rotation'][0];
        handler({data : ['event_occurred']});
        sinon.assert.calledWith(msg_received, 'motel::on_rotation', ['event_occurred']);
      });
    });
  }); 
});});
