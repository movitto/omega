pavlov.specify("Omega.Pages.IndexDialog", function(){
describe("Omega.Pages.IndexDialog", function(){
  var page, dialog;

  before(function(){
    page   = new Omega.Pages.Index();
    dialog = new Omega.Pages.IndexDialog({page : page});
  });

  after(function(){
    Omega.UI.Dialog.remove();
  })

  it("has a handle to page the dialog is on", function(){
    assert(dialog.page).equals(page);
  });

  describe("#wire_up", function(){
    after(function(){
      Omega.Test.clear_events();
    });

    it("registered login field enter key handlers", function(){
      assert(dialog.login_fields[0]).doesNotHandle('keypress');
      assert(dialog.login_fields[1]).doesNotHandle('keypress');
      dialog.wire_up();
      assert(dialog.login_fields[0]).handles('keypress');
      assert(dialog.login_fields[1]).handles('keypress');
      /// TODO ensure event handler calls _login_clicked only when enter key is pressed
    });

    it("registers login button event handlers", function(){
      assert(dialog.login_button).doesNotHandle('click');
      dialog.wire_up();
      assert(dialog.login_button).handles('click');
    });

    it("registers register button event handlers", function(){
      assert(dialog.register_button).doesNotHandle('click');
      dialog.wire_up();
      assert(dialog.register_button).handles('click');
    });
  });

  describe("#follow_node", function(){
    var node, show_dialog;

    before(function(){
      node = new Omega.Node();

      show_dialog = sinon.spy(dialog, 'show_critical_err_dialog');
    });

    it("listens for node closed and disconnection error events", function(){
      dialog.follow_node(node);
      assert(node).handlesEvent('error');
      assert(node).handlesEvent('closed');
    });

    describe("on node disconnection", function(){
      it("shows critical err dialog", function(){
        dialog.follow_node(node);
        node.dispatchEvent({type: 'error', disconnected: true, error : {class : 'disconnected'}});
        sinon.assert.called(show_dialog);
      });
    });

    describe("on node closed", function(){
      it("shows critical err dialog", function(){
        dialog.follow_node(node);
        node.dispatchEvent({type: 'closed'});
        sinon.assert.called(show_dialog);
      });
    })
  });

  describe("#show_critical_err_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_critical_err_dialog();
      sinon.assert.called(spy);
    });

    it("displays critical err dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_critical_err_dialog();
      assert(dialog.div_id).equals('#critical_err_dialog');
    });

    it("sets the critical error title/message", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_critical_err_dialog('CE', 'Disconnected');
      assert(dialog.title).equals('CE');
      assert($('#critical_err').html()).equals('Disconnected');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_critical_err_dialog();
      assert(dialog.dialog()).isVisible();
    });

    it("keeps the dialog open", function(){
      var dialog = new Omega.Pages.IndexDialog();
      var keep_open = sinon.spy(dialog, 'keep_open');
      dialog.show_critical_err_dialog();
      sinon.assert.called(keep_open);
    });
  });

  describe("#show_login_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_login_dialog();
      sinon.assert.called(spy);
    });

    it("displays login dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_login_dialog();
      assert(dialog.title).equals('Login');
      assert(dialog.div_id).equals('#login_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
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
      var dialog = new Omega.Pages.IndexDialog({page: page});
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_register_dialog();
      sinon.assert.called(spy);
    });

    it("generates a recaptcha", function(){
      var spy = sinon.spy(Recaptcha, 'create')
      var dialog = new Omega.Pages.IndexDialog({page: page});
      dialog.show_register_dialog();
      sinon.assert.calledWith(spy, Omega.Config.recaptcha_pub, "omega_recaptcha")
    });

    it("displays register dialog", function(){
      var dialog = new Omega.Pages.IndexDialog({page: page});
      dialog.show_register_dialog();
      assert(dialog.title).equals('Register');
      assert(dialog.div_id).equals('#register_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog({page: page});
      dialog.show_register_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_login_failed_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_login_failed_dialog();
      sinon.assert.called(spy);
    });

    it("displays login failed dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_login_failed_dialog();
      assert(dialog.title).equals('Login Failed');
      assert(dialog.div_id).equals('#login_failed_dialog');
    });

    it("sets login error", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_login_failed_dialog('invalid credentials');
      assert($('#login_err').html()).equals('Login Failed: invalid credentials');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_login_failed_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_registration_submitted_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_registration_submitted_dialog();
      sinon.assert.called(spy);
    });

    it("displays registration submitted dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_registration_submitted_dialog();
      assert(dialog.title).equals('Registration Submitted');
      assert(dialog.div_id).equals('#registration_submitted_dialog');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_registration_submitted_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("#show_registration_failed_dialog", function(){
    it("hides the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      var spy = sinon.spy(dialog, 'hide');
      dialog.show_registration_failed_dialog();
      sinon.assert.called(spy);
    });

    it("displays registration failed dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_registration_failed_dialog();
      assert(dialog.title).equals('Registration Failed');
      assert(dialog.div_id).equals('#registration_failed_dialog');
    });

    it("sets registration error", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_registration_failed_dialog('invalid email');
      assert($('#registration_err').html()).equals('Failed to create account: invalid email');
    });

    it("shows the dialog", function(){
      var dialog = new Omega.Pages.IndexDialog();
      dialog.show_registration_failed_dialog();
      assert(dialog.dialog()).isVisible();
    });
  });

  describe("login button clicked", function(){
    var dialog, page, login;

    before(function(){
      page = new Omega.Pages.Index();
      dialog = page.dialog;
      dialog.wire_up();

      $('#login_username').attr('value', 'uid');
      $('#login_password').attr('value', 'ups');

      login = sinon.stub(Omega.Session, 'login')
    })

    after(function(){
      Omega.Session.login.restore();
      Omega.Test.clear_events();
    })

    it("logs user in with session", function(){
      dialog.login_button.click();
      sinon.assert.calledWith(login, sinon.match(function(v){
        return v.id == 'uid' && v.password == 'ups';
      }), page.node);
    });

    describe("login error", function(){
      it("shows login_failed dialog", function(){
        dialog.login_button.click();

        var login_callback = login.getCall(0).args[2];
        spy = sinon.spy(dialog, 'show_login_failed_dialog');
        login_callback.apply(null, [{error: {message: 'invalid credentials'}}]);
        sinon.assert.calledWith(spy, 'invalid credentials');
      });
    });

    describe("valid login", function(){
      var login_callback, session, session_validated;

      before(function(){
        dialog.login_button.click();
        login_callback = login.getCall(0).args[2];
        session = new Omega.Session();
        session.id = 'foo'

        // stub out session validated
        sinon.stub(page, '_valid_session');
      })

      it("hides login dialog", function(){
        dialog.show_login_dialog();
        sinon.stub(dialog, 'hide');
        login_callback.apply(null, [session]);
        sinon.assert.called(dialog.hide);
      });

      it("sets page session", function(){
        login_callback.apply(null, [session]);
        assert(page.session).equals(session);
      });

      it("invokes page._valid_session", function(){
        login_callback.apply(null, [session]);
        sinon.assert.called(page._valid_session);
      })
    });
  });

  describe("register button clicked", function(){
    var page, dialog;

    before(function(){
      page = new Omega.Pages.Index();
      dialog = page.dialog;
      dialog.wire_up();

      $('#register_username').attr('value', 'uid');
      $('#register_password').attr('value', 'ups');
      $('#register_email').attr('value', 'uem');
    });

    after(function(){
      Omega.Test.clear_events();
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

