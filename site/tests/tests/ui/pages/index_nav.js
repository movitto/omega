pavlov.specify("Omega.UI.IndexNav", function(){
describe("Omega.UI.IndexNav", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  after(function(){
    if(Omega.UI.IndexNav.prototype.show_login_controls.restore)
      Omega.UI.IndexNav.prototype.show_login_controls.restore();
    if(Omega.UI.IndexNav.prototype.show_logout_controls.restore)
      Omega.UI.IndexNav.prototype.show_logout_controls.restore();
  });

  it("has a handle to page the nav is on", function(){
    var nav = new Omega.UI.IndexNav({page : page});
    assert(nav.page).equals(page);
  });

  describe("#wire_up", function(){
    var nav;

    before(function(){
      nav = new Omega.UI.IndexNav({page : page});
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("registers login link event handlers", function(){
      assert(nav.login_link).doesNotHandle('click');
      nav.wire_up();
      assert(nav.login_link).handles('click');
    });

    it("registers logout link event handlers", function(){
      assert(nav.logout_link).doesNotHandle('click');
      nav.wire_up();
      assert(nav.logout_link).handles('click');
    });

    it("registers register link event handlers", function(){
      assert(nav.register_link).doesNotHandle('click');
      nav.wire_up();
      assert(nav.register_link).handles('click');
    });
  });

  describe("user clicks login link", function(){
    var nav;

    before(function(){
      page.dialog  = new Omega.UI.IndexDialog({page: page});
      nav = new Omega.UI.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes index_dialog.show_login_dialog", function(){
      page.dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(page.dialog, 'show_login_dialog');
      nav.login_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks register link", function(){
    var nav;

    before(function(){
      page.dialog  = new Omega.UI.IndexDialog({page: page});
      nav = new Omega.UI.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes index_dialog.show_register_dialog", function(){
      var spy = sinon.spy(page.dialog, 'show_register_dialog');
      nav.register_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks logout link", function(){
    var nav;

    before(function(){
      page.session = new Omega.Session();
      nav = new Omega.UI.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes session.logout", function(){
      var spy = sinon.spy(page.session, 'logout');
      nav.logout_link.click();
      sinon.assert.called(spy);
    });

    it("shows login controls", function(){
      var spy = sinon.spy(nav, 'show_login_controls');
      nav.logout_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("#show_login_controls", function(){
    it("shows the register link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.register_link).isVisible();
    });

    it("shows the login link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.login_link).isVisible();
    });

    it("hides the account link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.account_link).isHidden();
    });

    it("hides the logout link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_login_controls();
      assert(nav.logout_link).isHidden();
    });
  });

  describe("#show_logout_controls", function(){
    it("hides the register link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.register_link).isHidden();
    });

    it("hides the login link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.login_link).isHidden();
    });

    it("shows the account link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.account_link).isVisible();
    });

    it("shows the logout link", function(){
      var nav = new Omega.UI.IndexNav();
      nav.show_logout_controls();
      assert(nav.logout_link).isVisible();
    });
  });
});});

