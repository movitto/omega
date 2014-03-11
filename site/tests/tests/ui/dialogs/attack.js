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
});});
