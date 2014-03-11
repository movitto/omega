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
