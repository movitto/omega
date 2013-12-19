pavlov.specify("Omega.Pages.AccountDialog", function(){
describe("Omega.Pages.AccountDialog", function(){
  var dialog;

  before(function(){
    dialog = new Omega.UI.AccountDialog();
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  describe("#show_incorrect_passwords_dialog", function(){
    it("hides the dialog", function(){
      var hide = sinon.spy(dialog, 'hide');
      dialog.show_incorrect_passwords_dialog();
      sinon.assert.calledWith(hide);
    });

    it("sets the dialog title", function(){
      dialog.show_incorrect_passwords_dialog();
      assert(dialog.title).equals('Passwords Do Not Match');
    });

    it("shows the incorrect_passwords dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_incorrect_passwords_dialog();
      sinon.assert.calledWith(show);
      assert(dialog.div_id).equals('#incorrect_passwords_dialog');
    });
  });

  describe("#show_update_error_dialog", function(){
    it("hides the dialog", function(){
      var hide = sinon.spy(dialog, 'hide');
      dialog.show_update_error_dialog('err');
      sinon.assert.calledWith(hide);
    });

    it("sets the dialog title", function(){
      dialog.show_update_error_dialog('err');
      assert(dialog.title).equals('Error Updating User');
    });

    it("sets the update error message in the dialog", function(){
      dialog.show_update_error_dialog('err');
      assert($('#update_user_error').html()).equals('Error: err');
    });

    it("shows the user update_error dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_update_error_dialog('err');
      sinon.assert.calledWith(show);
      assert(dialog.div_id).equals('#user_update_error_dialog');
    });
  });

  describe("#show_update_success_dialog", function(){
    it("hides the dialog", function(){
      var hide = sinon.spy(dialog, 'hide');
      dialog.show_update_success_dialog();
      sinon.assert.calledWith(hide);
    });

    it("sets the dialog title", function(){
      dialog.show_update_success_dialog();
      assert(dialog.title).equals('User Updated');
    });

    it("shows the user_updated dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_update_success_dialog();
      sinon.assert.calledWith(show);
    });

  });
});});

