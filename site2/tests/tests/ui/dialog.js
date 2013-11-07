pavlov.specify("Omega.UI.Dialog", function(){
describe("Omega.UI.Dialog", function(){
  describe("#show", function(){
    it("sets dialog title", function(){
      var dialog = new Omega.UI.Dialog({title : 'dialog1'});
      dialog.show();
      assert($('.ui-dialog-title').html()).equals('dialog1')
    })

    it("sets dialog content", function(){
      var dialog = new Omega.UI.Dialog({content : 'dialog1'});
      dialog.show();
      assert($('#omega-dialog').html()).equals('dialog1')
    })

    it("opens dialog", function(){
      var dialog = new Omega.UI.Dialog();
      dialog.show();
      assert($('#omega-dialog')).isVisible();
    })
  })

  describe("#hide", function(){
    it("closes the dialog", function(){
      var dialog = new Omega.UI.Dialog();
      dialog.show();
      dialog.hide();
      assert($('#omega-dialog')).isHidden();
    })
  })
});});
