pavlov.specify("Omega.Pages.IndexNav", function(){
describe("Omega.Pages.IndexNav", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  after(function(){
    if(Omega.Pages.IndexNav.prototype.show_login_controls.restore)
      Omega.Pages.IndexNav.prototype.show_login_controls.restore();
    if(Omega.Pages.IndexNav.prototype.show_logout_controls.restore)
      Omega.Pages.IndexNav.prototype.show_logout_controls.restore();
  });

  it("has a handle to page the nav is on", function(){
    var nav = new Omega.Pages.IndexNav({page : page});
    assert(nav.page).equals(page);
  });

  describe("#wire_up", function(){
    var nav;

    before(function(){
      nav = new Omega.Pages.IndexNav({page : page});
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
      page.dialog  = new Omega.Pages.IndexDialog({page: page});
      nav = new Omega.Pages.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes index_dialog.show_login_dialog", function(){
      page.dialog = new Omega.Pages.IndexDialog();
      sinon.spy(page.dialog, 'show_login_dialog');
      nav.login_link.click();
      sinon.assert.called(page.dialog.show_login_dialog);
    });
  });

  describe("user clicks register link", function(){
    var nav;

    before(function(){
      page.dialog  = new Omega.Pages.IndexDialog({page: page});
      nav = new Omega.Pages.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes index_dialog.show_register_dialog", function(){
      sinon.spy(page.dialog, 'show_register_dialog');
      nav.register_link.click();
      sinon.assert.called(page.dialog.show_register_dialog);
    });
  });

  describe("user clicks logout link", function(){
    var nav, session;

    before(function(){
      page.session = session = new Omega.Session();
      nav = new Omega.Pages.IndexNav({page : page});
      nav.wire_up();
    });

    after(function(){
      Omega.Test.clear_events();
    });

    it("invokes session.logout", function(){
      sinon.spy(page.session, 'logout');
      nav.logout_link.click();
      sinon.assert.called(session.logout);
    });

    it("hides the missions button", function(){
      sinon.spy(page.canvas.controls.missions_button, 'hide');
      nav.logout_link.click();
      sinon.assert.calledWith(page.canvas.controls.missions_button.hide);
    });

    it("invokes page invalid_session", function(){
      sinon.spy(page, '_invalid_session');
      nav.logout_link.click();
      sinon.assert.called(page._invalid_session);
    });
  });

  describe("#show_login_controls", function(){
    it("shows the register link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_login_controls();
      assert(nav.register_link).isVisible();
    });

    it("shows the login link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_login_controls();
      assert(nav.login_link).isVisible();
    });

    it("hides the account link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_login_controls();
      assert(nav.account_link).isHidden();
    });

    it("hides the logout link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_login_controls();
      assert(nav.logout_link).isHidden();
    });
  });

  describe("#show_logout_controls", function(){
    it("hides the register link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_logout_controls();
      assert(nav.register_link).isHidden();
    });

    it("hides the login link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_logout_controls();
      assert(nav.login_link).isHidden();
    });

    it("shows the account link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_logout_controls();
      assert(nav.account_link).isVisible();
    });

    it("shows the logout link", function(){
      var nav = new Omega.Pages.IndexNav();
      nav.show_logout_controls();
      assert(nav.logout_link).isVisible();
    });
  });
});});

