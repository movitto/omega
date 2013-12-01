pavlov.specify("Omega.Pages.AccountDetails", function(){
describe("Omega.Pages.AccountDetails", function(){
  var details, page;
  before(function(){
    page = new Omega.Pages.Account();
    details = page.details;
  });

  describe("#wire_up", function(){
    it("wires up account_info_update click events", function(){
      assert($('#account_info_update')).doesNotHandle('click');
      details.wire_up();
      assert($('#account_info_update')).handles('click');
    });

    describe("on account info update click", function(){
      it("invokes this.update", function(){
        var update = sinon.spy(details, '_update');
        details.wire_up();
        $('#account_info_update').click();
        sinon.assert.called(update);
      });
    });
  });

  describe("#update", function(){
    describe("passwords do not match", function(){
      it("shows incorrect passwords dialog", function(){
        sinon.stub(details, 'passwords_match').returns(false);
        var show_dialog = sinon.stub(page.dialog, 'show_incorrect_passwords_dialog');
        details._update();
        sinon.assert.called(show_dialog);
      });
    });

    describe("passwords match", function(){
      it("invokes users::update_user", function(){
        var user = new Omega.User();
        sinon.stub(details, 'user').returns(user);
        var http_invoke = sinon.spy(page.node, 'http_invoke');
        details._update();
        sinon.assert.calledWith(http_invoke, 'users::update_user',
          sinon.match.ofType(Omega.User), sinon.match.func);
        var ruser = http_invoke.getCall(0).args[1];
        assert(ruser).equals(user);
      });

      describe("users::update_user response", function(){
        var request_cb;

        before(function(){
          var http_invoke = sinon.spy(page.node, 'http_invoke');
          details._update();
          request_cb = http_invoke.getCall(0).args[2];
        });

        describe("error response", function(){
          it("shows update error dialog", function(){
            var show_dialog = sinon.spy(page.dialog, 'show_update_error_dialog');
            request_cb({error : {message : 'update error'}})
            sinon.assert.calledWith(show_dialog, 'update error');
          });
        });

        describe("success response", function(){
          it("shows update success dialog", function(){
            var show_dialog = sinon.spy(page.dialog, 'show_update_success_dialog');
            request_cb({});
            sinon.assert.called(show_dialog);
          });
        });
      });
    });
  });

  describe("#username", function(){
    it("sets account info username", function(){
      details.username('foobar');
      assert($('#account_info_username input').val()).equals('foobar');
    });

    it("returns account info username", function(){
      $('#account_info_username input').val('barfoo');
      assert(details.username()).equals('barfoo');
    });
  });

  describe("#password", function(){
    it("returns account info password", function(){
      $('#user_password').val('pass');
      assert(details.password()).equals('pass');
    });
  });

  describe("#password_confirmation", function(){
    it("returns account info password confirmation", function(){
      $('#user_confirm_password').val('pass');
      assert(details.password_confirmation()).equals('pass');
    });
  });

  describe("#email", function(){
    it("sets account info email", function(){
      details.email('foo@bar.com');
      assert($('#account_info_email input').val()).
        equals('foo@bar.com');
    });

    it("returns account info email", function(){
      $('#account_info_email input').val('bar@foo.com');
      assert(details.email()).equals('bar@foo.com');
    });
  });

  //describe("#gravatar", function(){
    //it("sets account info gravatar"); // NIY
  //});

  describe("#entities", function(){
    it("appends ships to account info ships container", function(){
      details.entities([new Omega.Ship({id : 'ship1'}), new Omega.Ship({id : 'ship2'})]);
      details.entities([new Omega.Ship({id : 'ship3'})]);
      assert($('#account_info_ships').html()).equals('ship1 ship2 ship3 ');
    });

    it("appends stations to account info stations container", function(){
      details.entities([new Omega.Station({id : 'station1'}), new Omega.Station({id : 'station2'})]);
      details.entities([new Omega.Station({id : 'station3'})]);
      assert($('#account_info_stations').html()).equals('station1 station2 station3 ');
    });
  });

  describe("#passwords_match", function(){
    describe("user password matches confirmation", function(){
      it("returns true", function(){
        sinon.stub(details, 'password').returns('pass');
        sinon.stub(details, 'password_confirmation').returns('pass');
        assert(details.passwords_match()).isTrue();
      });
    })

    describe("user password does not match confirmation", function(){
      it("returns false", function(){
        sinon.stub(details, 'password').returns('pass');
        sinon.stub(details, 'password_confirmation').returns('ssap');
        assert(details.passwords_match()).isFalse();
      });
    })
  });

  describe("#user", function(){
    it('returns user generated from account info', function(){
      sinon.stub(details, 'username').returns('user');
      sinon.stub(details, 'password').returns('pass');
      sinon.stub(details, 'email').returns('us@e.r');
      var user = details.user();
      assert(user.id).equals('user');
      assert(user.password).equals('pass');
      assert(user.email).equals('us@e.r');
    });
  });

  //describe("#add_badge", function(){
  //  it("adds badge to account info badges") // NIY
  //});
});});

pavlov.specify("Omega.Pages.AccountDialog", function(){
describe("Omega.Pages.AccountDialog", function(){
  var dialog;

  before(function(){
    dialog = new Omega.UI.AccountDialog();
  });

  after(function(){
    Omega.UI.Dialog.remove();
  });

  describe("#show_incorrect_passwords_dialog", function(){
    it("hides the dialog", function(){
      var hide = sinon.spy(dialog, 'hide');
      dialog.show_incorrect_passwords_dialog();
      sinon.assert.calledWith(hide);
    });

    it("sets the dialog title", function(){
      dialog.show_incorrect_passwords_dialog();
      assert(dialog.title).equals('Passwords Do Not Match');
    });

    it("shows the incorrect_passwords dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_incorrect_passwords_dialog();
      sinon.assert.calledWith(show);
      assert(dialog.div_id).equals('#incorrect_passwords_dialog');
    });
  });

  describe("#show_update_error_dialog", function(){
    it("hides the dialog", function(){
      var hide = sinon.spy(dialog, 'hide');
      dialog.show_update_error_dialog('err');
      sinon.assert.calledWith(hide);
    });

    it("sets the dialog title", function(){
      dialog.show_update_error_dialog('err');
      assert(dialog.title).equals('Error Updating User');
    });

    it("sets the update error message in the dialog", function(){
      dialog.show_update_error_dialog('err');
      assert($('#update_user_error').html()).equals('Error: err');
    });

    it("shows the user update_error dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_update_error_dialog('err');
      sinon.assert.calledWith(show);
      assert(dialog.div_id).equals('#user_update_error_dialog');
    });
  });

  describe("#show_update_success_dialog", function(){
    it("hides the dialog", function(){
      var hide = sinon.spy(dialog, 'hide');
      dialog.show_update_success_dialog();
      sinon.assert.calledWith(hide);
    });

    it("sets the dialog title", function(){
      dialog.show_update_success_dialog();
      assert(dialog.title).equals('User Updated');
    });

    it("shows the user_updated dialog", function(){
      var show = sinon.spy(dialog, 'show');
      dialog.show_update_success_dialog();
      sinon.assert.calledWith(show);
    });

  });
});});

pavlov.specify("Omega.Pages.Account", function(){
describe("Omega.Pages.Account", function(){
  var page;
  before(function(){
    page = new Omega.Pages.Account();
  });

  after(function(){
    if(Omega.Session.restore_from_cookie.restore) Omega.Session.restore_from_cookie.restore();
  });

  it("initializes local config", function(){
    assert(page.config).equals(Omega.Config);
  });

  it("inititalizes local node", function(){
    assert(page.node).isOfType(Omega.Node);
  });

  it("initializes account info dialog", function(){
    assert(page.dialog).isOfType(Omega.UI.AccountDialog);
  });

  it("initializes account info details", function(){
    assert(page.details).isOfType(Omega.UI.AccountDetails);
  });

  it("restores session from cookie", function(){
    var restore_from_cookie = sinon.spy(Omega.Session, 'restore_from_cookie');
    var acct = new Omega.Pages.Account();
    sinon.assert.called(restore_from_cookie);
  });

  it("validates sessions", function(){
    var session = new Omega.Session();
    sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

    var validate = sinon.spy(session, 'validate');
    var acct = new Omega.Pages.Account();
    sinon.assert.calledWith(validate, acct.node, sinon.match.func);
  });

  describe("session validated", function(){
    var acct, session, validate_cb, user;

    before(function(){
      session = new Omega.Session();
      sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
      var validate = sinon.spy(session, 'validate');
      acct = new Omega.Pages.Account();
      validate_cb = validate.getCall(0).args[1];

      user = new Omega.User({id : 'user', email : 'u@s.er'});
    });

    after(function(){
      if(Omega.Ship.owned_by.restore) Omega.Ship.owned_by.restore();
      if(Omega.Station.owned_by.restore) Omega.Station.owned_by.restore();
      if(Omega.Stat.get.restore) Omega.Stat.get.restore();
    });

    it("populates account info details container", function(){
      var username = sinon.spy(acct.details, 'username');
      var email    = sinon.spy(acct.details, 'email');
      var gravatar = sinon.spy(acct.details, 'gravatar');
      validate_cb({result : user});
      sinon.assert.calledWith(username, 'user');
      sinon.assert.calledWith(email,    'u@s.er');
      sinon.assert.calledWith(gravatar, 'u@s.er');
    });

    it("retrieves ships owned by user", function(){
      var owned_by = sinon.spy(Omega.Ship, 'owned_by');
      validate_cb({result : user});
      sinon.assert.calledWith(owned_by, session.user_id, acct.node, sinon.match.func);
    });

    describe("retrieve ships callback", function(){
      it("processes_entities with ships retrieved", function(){
        var owned_by = sinon.spy(Omega.Ship, 'owned_by');
        validate_cb({result : user});
        var owned_by_cb = owned_by.getCall(0).args[2];
        var process_entities = sinon.spy(acct, 'process_entities');
        var ships = [new Omega.Ship()];
        owned_by_cb(ships);
        sinon.assert.calledWith(process_entities, ships);
      })
    });

    it("retrieves stations owned by user", function(){
      var owned_by = sinon.spy(Omega.Station, 'owned_by');
      validate_cb({result : user});
      sinon.assert.calledWith(owned_by, session.user_id, acct.node, sinon.match.func);
    });

    describe("retrieve stations callback", function(){
      it("processes_entities with ships retrieved", function(){
        var owned_by = sinon.spy(Omega.Station, 'owned_by');
        validate_cb({result : user});
        var owned_by_cb = owned_by.getCall(0).args[2];
        var process_entities = sinon.spy(acct, 'process_entities');
        var stations = [new Omega.Station()];
        owned_by_cb(stations);
        sinon.assert.calledWith(process_entities, stations);
      });
    });

    it("retrieves user stats", function(){
      var get_stat = sinon.spy(Omega.Stat, 'get');
      validate_cb({result : user});
      sinon.assert.calledWith(get_stat, 'with_most', ['entities', 10], acct.node, sinon.match.func);
    });

    describe("retrieve stats callback", function(){
      it("processes_stats with stats retrieved", function(){
        var get_stat = sinon.spy(Omega.Stat, 'get');
        validate_cb({result : user});
        var get_stat_cb = get_stat.getCall(0).args[3];
        var process_stats = sinon.spy(acct, 'process_stats');
        var stats = [new Omega.Stat({value : []})];
        get_stat_cb(stats);
        sinon.assert.calledWith(process_stats, stats);
      })
    });
  });

  describe("invalid session", function(){
    it("clears session", function(){
      session = new Omega.Session();
      sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
      var validate = sinon.spy(session, 'validate');
      var acct = new Omega.Pages.Account();
      validate_cb = validate.getCall(0).args[1];
      validate_cb({error : {}})
      assert(acct.session).isNull();
    })
  });

  describe("#wire_up", function(){
    it("wires up details", function(){
      var wire_up_details = sinon.spy(page.details, 'wire_up');
      page.wire_up();
      sinon.assert.called(wire_up_details);
    });
  });

  describe("#process_entities", function(){
    it("processes each entity", function(){
      var entities = [new Omega.Ship(), new Omega.Station()];
      var process_entity = sinon.spy(page, 'process_entity')
      page.process_entities(entities);
      sinon.assert.calledWith(process_entity, entities[0]);
      sinon.assert.calledWith(process_entity, entities[1]);
    });
  });

  describe("#process_entity", function(){
    it("adds entity to account info entity details", function(){
      var add_entity = sinon.spy(page.details, 'entities');
      var ship = new Omega.Ship();
      page.process_entity(ship);
      sinon.assert.calledWith(add_entity, ship);
    });
  });

  //describe("#process_stats", function(){
  //  describe("local user is in stats", function(){
  //    it("adds badge to account info badges") // NIY
  //  })
  //});
});});
