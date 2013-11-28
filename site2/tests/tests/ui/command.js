pavlov.specify("Omega.UI.CommandDialog", function(){
describe("Omega.UI.CommandDialog", function(){
  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe('#append_error', function(){
    it('appends error to dialog', function(){
      var dialog = new Omega.UI.CommandDialog();
      dialog.append_error('command error');
      assert($('#command_error').html()).equals('command error')
    });
  });
});});
