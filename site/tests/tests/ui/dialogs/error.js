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

});});
