pavlov.specify("Omega.UI.IndexNav", function(){
describe("Omega.UI.IndexNav", function(){
  after(function(){
    if(Omega.UI.IndexNav.prototype.show_login_controls.restore)
      Omega.UI.IndexNav.prototype.show_login_controls.restore();
    if(Omega.UI.IndexNav.prototype.show_logout_controls.restore)
      Omega.UI.IndexNav.prototype.show_logout_controls.restore();
  });

  describe("user session is not null", function(){
    it("shows logout controls", function(){
      var spy = sinon.spy(Omega.UI.IndexNav.prototype, 'show_logout_controls');
      var session = new Omega.Session();
      var nav     = new Omega.UI.IndexNav({session : session});
      sinon.assert.called(spy);
    });
  });

  describe("user session is null", function(){
    it("shows login controls", function(){
      var spy = sinon.spy(Omega.UI.IndexNav.prototype, 'show_login_controls');
      var nav     = new Omega.UI.IndexNav({session : null});
      sinon.assert.called(spy);
    });
  });

  describe("user clicks login link", function(){
    it("invokes index_dialog.show_login_dialog", function(){
      var dialog  = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'show_login_dialog');
      var nav     = new Omega.UI.IndexNav({index_dialog : dialog});
      nav.login_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks register link", function(){
    it("invokes index_dialog.show_register_dialog", function(){
      var dialog  = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'show_register_dialog');
      var nav     = new Omega.UI.IndexNav({index_dialog : dialog});
      nav.register_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks logout link", function(){
    it("invokes session.logout", function(){
      var session = new Omega.Session();
      var spy = sinon.spy(session, 'logout');
      var nav     = new Omega.UI.IndexNav({session : session});
      nav.logout_link.click();
      sinon.assert.called(spy);
    });

    it("shows login controls", function(){
      var session = new Omega.Session();
      var nav     = new Omega.UI.IndexNav({session : session});
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

pavlov.specify("Omega.UI.IndexDialog", function(){
describe("Omega.UI.IndexDialog", function(){
  describe("#show_login_dialog", function(){
    it("displays login dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      assert(dialog.title).equals($('#login_dialog_title').html())
      assert(dialog.content).equals($('#login_dialog').html())
    };

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      assert($('#omega-dialog')).isVisible();
    });
  });

  describe("#show_register_dialog", function(){
    it("displays register dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_register_dialog();
      assert(dialog.title).equals($('#register_dialog_title').html())
      assert(dialog.content).equals($('#register_dialog').html())
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_register_dialog();
      assert($('#omega-dialog')).isVisible();
    });
  });

  describe("login button clicked", function(){
    it("closes login dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      dialog.login_button.click();
      assert($('#omega-dialog')).isHidden();
    });

    it("logs user in with session", function(){
    });
  })

  describe("register button clicked", function(){
    it("sends user register confirmation")

    it("displays registration email dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_register_dialog();
      dialog.register_button.click();
      assert(dialog.title).equals($('#register_dialog_title').html());
      assert(dialog.content).equals($('#register_submitted_dialog').html());
    });
  });
});});

pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  var index;

  before(function(){
    index = new Omega.Pages.Index();
  });

  it("restores session from cookie", function(){
  });

  it("has an index dialog", function(){
    assert(index.dialog).isOfType(Omega.UI.IndexDialog);
  });

  it("has an index nav", function(){
    assert(index.nav).isOfType(Omega.UI.IndexNav);
    assert(index.nav.index_dialog).isSameAs(index.dialog);
  });
});});
