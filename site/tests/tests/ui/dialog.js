pavlov.specify("Omega.UI.Dialog", function(){
describe("Omega.UI.Dialog", function(){
  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe('#dialog', function(){
    it('returns dialog dom component', function(){
      var dialog = new Omega.UI.Dialog({div_id: '#foo'})
      assert(dialog.dialog().selector).equals($('#foo').selector);
    });
  });

  describe("#show", function(){
    before(function(){
      Omega.Test.enable_dialogs();
    });

    after(function(){
      Omega.Test.reset_dialogs();
    });

    it("sets dialog title", function(){
      var dialog = new Omega.UI.Dialog({title : 'dialog1'});
      dialog.show();
      assert($('.ui-dialog-title').html()).equals('dialog1')
    });

    it("attaches dialog to dom component", function(){
      var dialog = new Omega.UI.Dialog();
      var dom = dialog.dialog();
      var stub = sinon.stub(dialog, 'dialog').returns(dom); // always return same element
      sinon.spy(dom, 'dialog');
      dialog.show();
      sinon.assert.calledWith(dom.dialog, 'open');
    });

    it("opens dialog", function(){
      var dialog = new Omega.UI.Dialog();
      dialog.show();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#hide", function(){
    before(function(){
      Omega.Test.enable_dialogs();
    });

    after(function(){
      Omega.Test.reset_dialogs();
    });

    it("closes the dialog", function(){
      var dialog = new Omega.UI.Dialog();
      dialog.show();
      dialog.hide();
      assert(dialog.dialog()).isHidden();
    });
  });

  describe("#remove", function(){
    it("removes all dialogs", function(){
      $('#qunit-fixture').append('<div class="ui-dialog" />');
      assert($('#qunit-fixture .ui-dialog').length).equals(1);
      Omega.UI.Dialog.remove();
      assert($('#qunit-fixture .ui-dialog').length).equals(0);
    });
  });

  describe("#keep_open", function(){
    before(function(){
      Omega.Test.enable_dialogs();
    });

    after(function(){
      Omega.Test.reset_dialogs();
    });

    it("disables dialog escape key", function(){
      var dialog = new Omega.UI.Dialog();
      dialog.keep_open();
      assert(dialog.dialog().dialog('option', 'closeOnEscape')).isFalse();
    });

    it("hides dialog close button", function(){
      var dialog = new Omega.UI.Dialog();
      dialog.show();
      dialog.keep_open();
      assert($('.ui-dialog-titlebar-close')).isHidden();
    });
  });
});});
