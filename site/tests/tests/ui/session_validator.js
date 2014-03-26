// TODO test independently (currently testing through index page mixin)
pavlov.specify("Omega.UI.SessionValidator", function(){
describe("Omega.UI.SessionValidator", function(){
  describe("#validate_session", function(){
    var index, session_valid, session_invalid;

    before(function(){
      index = new Omega.Pages.Index();

      session_valid = sinon.stub(index, '_session_validated');
      session_invalid = sinon.stub(index, '_session_invalid');
    });

    after(function(){
      if(Omega.Session.restore_from_cookie.restore) Omega.Session.restore_from_cookie.restore();
    });

    it("restores session from cookie", function(){
      var restore = sinon.spy(Omega.Session, 'restore_from_cookie');
      index.validate_session();
      sinon.assert.called(restore);
    });

    describe("session is not null", function(){
      it("validates session", function(){
        var session = new Omega.Session();
        var spy = sinon.spy(session, 'validate');
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);
        index.validate_session();
        sinon.assert.calledWith(spy, index.node);
      });

      describe("session is not valid", function(){
        var session, validate_cb;

        before(function(){
          session = new Omega.Session();
          var spy = sinon.spy(session, 'validate');
          var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

          index.validate_session();
          validate_cb = spy.getCall(0).args[1];
        })

        it("invokes session_invalid", function(){
          validate_cb.apply(null, [{error : {}}]);
          sinon.assert.called(session_invalid);
        });
      });

      describe("user session is valid", function(){
        var session, validate_cb, session_validated;

        before(function(){
          session = new Omega.Session({user_id: 'user1'});
          var spy = sinon.spy(session, 'validate');
          sinon.stub(Omega.Session, 'restore_from_cookie').returns(session);

          index.validate_session();
          validate_cb = spy.getCall(0).args[1];
        })

        after(function(){
          Omega.Session.restore_from_cookie.restore();
        })

        it("sets session.user", function(){
          var user = Omega.Gen.user();
          validate_cb.apply(null, [{result : user}]);
          assert(session.user).equals(user);
        });

        it("invokes session_validated", function(){
          validate_cb.apply(null, [{}]);
          sinon.assert.called(session_valid);
        })
      });
    });

    describe("#session is null", function(){
      it("invokes session_invalid", function(){
        var stub = sinon.stub(Omega.Session, 'restore_from_cookie').returns(null);
        index.validate_session();
        sinon.assert.called(session_invalid);
      });
    });
  });

  describe("#_session_validated", function(){
    var index;
    before(function(){
      index = new Omega.Pages.Index();
      index.session = new Omega.Session();
    });

    it("shows logout controls", function(){
      var spy = sinon.spy(index.nav, 'show_logout_controls');
      index._session_validated();
      sinon.assert.called(spy);
    });

    it("shows the missions button", function(){
      var show = sinon.spy(index.canvas.controls.missions_button, 'show')
      index._session_validated();
      sinon.assert.called(show);
    });

    it("handles events", function(){
      var handle_events = sinon.spy(index, '_handle_events');
      index._session_validated();
      sinon.assert.called(handle_events);
    });

    it("invokes the specified callback", function(){
      var cb = sinon.spy();
      index._session_validated(cb);
      sinon.assert.called(cb);
    })
  });

  describe("#_session_invalid", function(){
    var session, index;
    before(function(){
      index = new Omega.Pages.Index();
      session = new Omega.Session();
      index.session = session;
    });

    after(function(){
      if(Omega.Session.login.restore) Omega.Session.login.restore();
    });

    it("clears session cookies", function(){
      var clear_cookies = sinon.spy(session, 'clear_cookies');
      index._session_invalid();
      sinon.assert.called(clear_cookies);
    });

    it("nullifies session", function(){
      index._session_invalid();
      assert(index.session).isNull();
    });

    it("shows login controls", function(){
      var show_login = sinon.spy(index.nav, 'show_login_controls');
      index._session_invalid();
      sinon.assert.called(show_login);
    });

    it("logs anon user in", function(){
      var login = sinon.stub(Omega.Session, 'login')
      index._session_invalid();
      sinon.assert.calledWith(login, sinon.match(function(u){
        return u.id == Omega.Config.anon_user && u.password == Omega.Config.anon_pass;
      }), index.node, sinon.match.func);
    });

    it("handles events", function(){
      var login = sinon.stub(Omega.Session, 'login')
      index._session_invalid();

      var handle_events = sinon.spy(index, '_handle_events');
      var login_cb = login.getCall(0).args[2];
      login_cb({});
      sinon.assert.called(handle_events);
    });

    it("invokes the specified callback", function(){
      var cb = sinon.spy();
      var login = sinon.stub(Omega.Session, 'login')
      index._session_invalid(cb);
      var handle_events = sinon.spy(index, '_handle_events');
      var login_cb = login.getCall(0).args[2];
      login_cb({});
      sinon.assert.called(cb);
    });
  });

  describe("#handle_events", function(){
    var index;
    before(function(){
      index = new Omega.Pages.Index();
    });

    it("tracks all motel and manufactured events", function(){
      var events = Omega.UI.CommandTracker.prototype.motel_events.concat(
                   Omega.UI.CommandTracker.prototype.manufactured_events);
      var track = sinon.stub(index.command_tracker, 'track');
      index._handle_events();
      for(var e = 0; e < events.length; e++)
        sinon.assert.calledWith(track, events[e]);
    });
  });
});});
