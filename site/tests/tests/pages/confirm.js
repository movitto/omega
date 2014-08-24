pavlov.specify("Omega.Pages.Confirm", function(){
describe("Omega.Pages.Confirm", function(){ /// NIY
  var page;

  before(function(){
    page = new Omega.Pages.Confirm();
  });

  /// base page mixin test
  it("has a node", function(){
    assert(page.node).isOfType(Omega.Node);
  });
});});
