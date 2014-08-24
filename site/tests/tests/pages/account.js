pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Account();
  });

  /// base page mixin test
  it("has a node", function(){
    assert(page.node).isOfType(Omega.Node);
  });
});});
