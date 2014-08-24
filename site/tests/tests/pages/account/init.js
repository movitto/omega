pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Account();
  });

  it("has an account info dialog instance", function(){
    assert(page.dialog).isOfType(Omega.Pages.AccountDialog);
  });

  it("has an account info details instance", function(){
    assert(page.details).isOfType(Omega.Pages.AccountDetails);
  });

  describe("#wire_up", function(){
    it("wires up details", function(){
      var wire_up_details = sinon.spy(page.details, 'wire_up');
      page.wire_up();
      sinon.assert.called(wire_up_details);
    });
  });
});});
