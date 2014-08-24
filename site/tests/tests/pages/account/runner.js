pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Account();
  });

  describe("#start", function(){
    before(function(){
      sinon.stub(page, 'validate_session');
    });

    it("validates session", function(){
      page.start();
      sinon.assert.called(page.validate_session);
    });
  });
});});
