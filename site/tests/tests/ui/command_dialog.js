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

  describe("#instance", function(){
    it("provides singleton instance of the dialog", function(){
      assert(Omega.UI.CommandDialog.instance()).
        isOfType(Omega.UI.CommandDialog);
      assert(Omega.UI.CommandDialog.instance()).
        equals(Omega.UI.CommandDialog.instance());
    });
  });
});});
