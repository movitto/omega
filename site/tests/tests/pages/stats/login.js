pavlov.specify("Omega.Pages.Stats", function(){
describe("Omega.Pages.Stats", function(){
  var old_cookies, page;

  before(function(){
    old_cookies = Omega.Session.cookies_enabled;
    page = new Omega.Pages.Stats();
    sinon.stub(Omega.Session, 'login');
  });

  after(function(){
    Omega.Session.cookies_enabled = old_cookies;
    Omega.Session.login.restore();
  });

  describe("#login", function(){
    it("disables session cookies", function(){
      page.login();
      assert(Omega.Session.cookies_enabled).isFalse();
    });

    it("logins anon user", function(){
      page.login();
      sinon.assert.calledWith(Omega.Session.login,
                              sinon.match.ofType(Omega.User), page.node);

      var user = Omega.Session.login.getCall(0).args[0];
      assert(user.id).equals(Omega.Config.anon_user)
      assert(user.password).equals(Omega.Config.anon_pass)
    });
  });
});});
