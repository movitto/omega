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

  describe("user session is not null", function(){
    it("shows logout controls", function(){
      var spy = sinon.spy(Omega.UI.IndexNav.prototype, 'show_logout_controls');
      page.session = new Omega.Session();
      var nav      = new Omega.UI.IndexNav({page : page});
      sinon.assert.called(spy);
    });
  });

  describe("user session is null", function(){
    it("shows login controls", function(){
      var spy = sinon.spy(Omega.UI.IndexNav.prototype, 'show_login_controls');
      var nav     = new Omega.UI.IndexNav({page : page});
      sinon.assert.called(spy);
    });
  });

  describe("user clicks login link", function(){
    it("invokes index_dialog.show_login_dialog", function(){
      page.dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(page.dialog, 'show_login_dialog');
      var nav     = new Omega.UI.IndexNav({page : page});
      nav.login_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks register link", function(){
    it("invokes index_dialog.show_register_dialog", function(){
      page.dialog  = new Omega.UI.IndexDialog({page: page});
      var spy = sinon.spy(page.dialog, 'show_register_dialog');
      var nav     = new Omega.UI.IndexNav({page : page});
      nav.register_link.click();
      sinon.assert.called(spy);
    });
  });

  describe("user clicks logout link", function(){
    it("invokes session.logout", function(){
      page.session = new Omega.Session();
      var spy = sinon.spy(page.session, 'logout');
      var nav     = new Omega.UI.IndexNav({page : page});
      nav.logout_link.click();
      sinon.assert.called(spy);
    });

    it("shows login controls", function(){
      page.session = new Omega.Session();
      var nav     = new Omega.UI.IndexNav({page : page});
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
  after(function(){
    Omega.UI.Dialog.remove();
  })

  describe("#show_login_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_login_dialog();
      sinon.assert.called(spy);
    });

    it("displays login dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      assert(dialog.title).equals('Login');
      assert(dialog.div_id).equals('#login_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_register_dialog", function(){
    var page;

    before(function(){
      page = new Omega.Pages.Index();
    })

    after(function(){
      if(Recaptcha.create.restore) Recaptcha.create.restore();
    })

    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog({page: page});
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_register_dialog();
      sinon.assert.called(spy);
    });

    it("generates a recaptcha", function(){
      var spy = sinon.spy(Recaptcha, 'create')
      var dialog = new Omega.UI.IndexDialog({page: page});
      dialog.show_register_dialog();
      sinon.assert.calledWith(spy, page.config.recaptcha_pub, "omega_recaptcha")
    });

    it("displays register dialog", function(){
      var dialog = new Omega.UI.IndexDialog({page: page});
      dialog.show_register_dialog();
      assert(dialog.title).equals('Register');
      assert(dialog.div_id).equals('#register_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog({page: page});
      dialog.show_register_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_login_failed_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_login_failed_dialog();
      sinon.assert.called(spy);
    });

    it("displays login failed dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_failed_dialog();
      assert(dialog.title).equals('Login Failed');
      assert(dialog.div_id).equals('#login_failed_dialog');
    });

    it("sets login error", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_failed_dialog('invalid credentials');
      assert($('#login_err').html()).equals('Login Failed: invalid credentials');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_login_failed_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_registration_submitted_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_registration_submitted_dialog();
      sinon.assert.called(spy);
    });

    it("displays registration submitted dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_submitted_dialog();
      assert(dialog.title).equals('Registration Submitted');
      assert(dialog.div_id).equals('#registration_submitted_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_submitted_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_registration_failed_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_registration_failed_dialog();
      sinon.assert.called(spy);
    });

    it("displays registration failed dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_failed_dialog();
      assert(dialog.title).equals('Registration Failed');
      assert(dialog.div_id).equals('#registration_failed_dialog');
    });

    it("sets registration error", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_failed_dialog('invalid email');
      assert($('#registration_err').html()).equals('Failed to create account: invalid email');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.UI.IndexDialog();
      dialog.show_registration_failed_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("login button clicked", function(){
    var dialog, page;

    before(function(){
      page = new Omega.Pages.Index();
      dialog = page.dialog;

      $('#login_username').attr('value', 'uid');
      $('#login_password').attr('value', 'ups');
    })

    after(function(){
      if(Omega.Session.login.restore) Omega.Session.login.restore();
    })

    it("logs user in with session", function(){
      var spy = sinon.spy(Omega.Session, 'login')
      dialog.login_button.click();
      sinon.assert.calledWith(spy, sinon.match(function(v){
        return v.id == 'uid' && v.password == 'ups';
      }), page.node);
    });

    describe("login error", function(){
      it("shows login_failed dialog", function(){
        var spy = sinon.stub(Omega.Session, 'login')
        dialog.login_button.click();

        var login_callback = spy.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_login_failed_dialog');
        login_callback.apply(null, [{error: {message: 'invalid credentials'}}]);
        sinon.assert.calledWith(spy, 'invalid credentials');
      });
    });

    describe("valid login", function(){
      var login_callback, session;

      before(function(){
        var spy = sinon.spy(Omega.Session, 'login')
        dialog.login_button.click();
        login_callback = spy.getCall(0).args[2];
        session = new Omega.Session();
      })

      it("hides login dialog", function(){
        dialog.show_login_dialog();
        login_callback.apply(null, [session]);
        assert(dialog.dialog()).isHidden();
      });

      it("sets page session", function(){
        login_callback.apply(null, [session]);
        assert(page.session).equals(session);
      });

      it("shows page navigation logout controls", function(){
        var spy = sinon.spy(page.nav, 'show_logout_controls');
        login_callback.apply(null, [session]);
        sinon.assert.called(spy);
      });
    });
  });

  describe("register button clicked", function(){
    var page, dialog;

    before(function(){
      page = new Omega.Pages.Index();
      dialog = page.dialog;

      $('#register_username').attr('value', 'uid');
      $('#register_password').attr('value', 'ups');
      $('#register_email').attr('value', 'uem');
    });

    it("sends user registration", function(){
      var spy = sinon.spy(page.node, 'http_invoke');
      dialog.register_button.click();
      sinon.assert.calledWith(spy, 'users::register', sinon.match(function(v){
        // TODO also validate recaptcha / recaptcha response
        return v.id == 'uid' && v.password == 'ups' && v.email == 'uem';
      }));
    });

    describe("registration error", function(){
      it("shows registration failed dialog", function(){
        var spy = sinon.spy(page.node, 'http_invoke');
        dialog.register_button.click();

        var register_callback = spy.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_registration_failed_dialog');
        register_callback.apply(null, [{error: {message: 'invalid email'}}]);
        sinon.assert.calledWith(spy, 'invalid email');
      });
    });

    describe("successful registration", function(){
      it("displays registration email dialog", function(){
        var spy = sinon.spy(page.node, 'http_invoke');
        dialog.register_button.click();

        var register_callback = spy.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_registration_submitted_dialog');
        register_callback.apply(null, [{}])
        sinon.assert.called(spy);
      });
    });
  });
});});

pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  after(function(){
    if(Omega.Session.restore_from_cookie.restore) Omega.Session.restore_from_cookie.restore();
  });

  it("loads config", function(){
    var index = new Omega.Pages.Index();
    assert(index.config).equals(Omega.Config);
  });

  it("creates a new node", function(){
    var index = new Omega.Pages.Index();
    assert(index.node).isOfType(Omega.Node);
  });

  it("restores session from cookie", function(){
    var spy = sinon.spy(Omega.Session, 'restore_from_cookie');
    var index = new Omega.Pages.Index();
    sinon.assert.called(spy);
  });

  describe("session is not null", function(){
    it("validates session", function(){
      var session = new Omega.Session();
      var spy = sinon.spy(session, 'validate');
      var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
      var index = new Omega.Pages.Index();
      sinon.assert.calledWith(spy, index.node);
    });

    describe("session is not valid", function(){
      it("nullifies session", function(){
        var session = new Omega.Session();
        var spy = sinon.spy(session, 'validate');
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
        var index = new Omega.Pages.Index();

        var validate_cb = spy.getCall(0).args[1];
        validate_cb.apply(null, [{error : {}}]);
        assert(index.session).isNull();
      });
    })
  })

  it("has an index dialog", function(){
    var index = new Omega.Pages.Index();
    assert(index.dialog).isOfType(Omega.UI.IndexDialog);
    assert(index.dialog.page).isSameAs(index);
  });

  it("has an index nav", function(){
    var index = new Omega.Pages.Index();
    assert(index.nav).isOfType(Omega.UI.IndexNav);
    assert(index.nav.page).isSameAs(index);
  });
});});
