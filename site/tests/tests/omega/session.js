pavlov.specify("Omega.Session", function(){
describe("Omega.Session", function(){
  var session;

  before(function(){
    session = new Omega.Session();
  });

  after(function(){
    Omega.Session.prototype.clear_cookies();
  })

  describe("#set_cookies", function(){
    it("sets cookies", function(){
      var s = new Omega.Session({id : 'session1', user_id: 'foo'});
      s.set_cookies();
      assert($.cookie('omega-session')).equals('session1');
      assert($.cookie('omega-user')).equals('foo');
    });

    describe("cookies are disabled", function(){
      var old_config;

      before(function(){
        old_config = Omega.Session.cookies_enabled;
        Omega.Session.cookies_enabled = false;
      });

      after(function(){
        Omega.Session.cookies_enabled = old_config;
      });

      it("does nothing", function(){
        var s = new Omega.Session({id : 'session1', user_id: 'foo'});
        s.set_cookies();
        assert($.cookie('omega-session')).isUndefined();
        assert($.cookie('omega-user')).isUndefined();
      });
    });
  });

  describe("#clear_cookies", function(){
    after(function(){
      Omega.Session.prototype.clear_cookies();
    });

    it("clears session cookies", function(){
      $.cookie('omega-session', 'session1');
      $.cookie('omega-user', 'foo');

      session.clear_cookies();
      assert($.cookie('omega-session')).isUndefined();
      assert($.cookie('omega-user')).isUndefined();
    });

    describe("cookies are disabled", function(){
      var old_config;

      before(function(){
        old_config = Omega.Session.cookies_enabled;
        Omega.Session.cookies_enabled = false;
      });

      after(function(){
        Omega.Session.cookies_enabled = old_config;
      });

      it("does nothing", function(){
        $.cookie('omega-session', 'session1');
        $.cookie('omega-user', 'foo');
        session.clear_cookies();
        assert($.cookie('omega-session')).equals('session1');
        assert($.cookie('omega-user')).equals('foo');
      });
    });
  });

  describe("#set_headers_on", function(){
    it('sets session headers on node', function(){
      var node = new Omega.Node();
      session.id = 'session1';
      session.user_id = 'user1';

      session.set_headers_on(node);
      assert(node.http.headers['session_id']).equals('session1')
      assert(node.http.headers['source_node']).equals('user1')
    });
  });
  
  describe("#clear_headers_on", function(){
    it("clears session headers on node", function(){
      var node = new Omega.Node();

      session.id = 'session1';
      session.user_id = 'user1';

      session.clear_headers_on(node);
      assert(node.http.headers['session_id']).isNull();
      assert(node.http.headers['source_node']).isNull();
    });
  });

  describe("#validate", function(){
    it("sets session headers on given node", function(){
      var node = new Omega.Node();
      var stub = sinon.stub(node, 'http_invoke');

      var spy = sinon.spy(session, 'set_headers_on');
      session.validate(node);
      sinon.assert.calledWith(spy, node);
    });

    it("validates session via http request", function(){
      var node = new Omega.Node();
      var cb = function() {};
      var stub = sinon.stub(node, 'http_invoke');
      session.validate(node, cb);
      assert(stub.getCall(0).args[0]).equals('users::get_entity');
      assert(stub.getCall(0).args[3]).equals(cb);
    });
  });

  describe("#logout", function(){
    var node, cb, stub;

    before(function(){
      node = new Omega.Node();
      session.id = 'session1';
      cb   = sinon.spy();
      stub = sinon.stub(node, 'http_invoke');
    });

    it("invokes users::logout http request", function(){
      session.logout(node, cb)
      assert(stub.getCall(0).args[0]).equals('users::logout');
      assert(stub.getCall(0).args[1]).equals('session1');
    });

    describe("logout response handler", function(){
      var response;
      var handler;

      before(function(){
        session.logout(node, cb)
        handler = stub.getCall(0).args[2];
      });

      it("clears session headers on node", function(){
        var spy = sinon.spy(session, 'clear_headers_on')
        handler(response);
        sinon.assert.calledWith(spy, node);
      });

      it("clears session cookies", function(){
        var spy = sinon.spy(session, 'clear_cookies')
        handler(response);
        sinon.assert.called(spy);
      });

      describe("callback specified", function(){
        it("invokes callback", function(){
          handler(response)
          sinon.assert.called(cb)
        });
      });

      it("raises logout event", function(){
        var spy = sinon.spy();
        session.addEventListener('logout', spy);
        handler(response);
        sinon.assert.called(spy);
        assert(spy.getCall(0).args[0].data).equals(session);
      })
    });
  });

  describe("#restore_from_cookie", function(){
    describe("cookies are disabled", function(){
      var old_config;

      before(function(){
        old_config = Omega.Session.cookies_enabled;
        Omega.Session.cookies_enabled = false;
      });

      after(function(){
        Omega.Session.cookies_enabled = old_config;
        Omega.Session.prototype.clear_cookies();
      });

      it("returns null", function(){
        $.cookie('omega-user', 'user1');
        $.cookie('omega-session', 'session1');
        assert(Omega.Session.restore_from_cookie()).equals(null);
      });
    });

    describe("user and session not null", function(){
      it("returns a new Session", function(){
        $.cookie('omega-user', 'user1');
        $.cookie('omega-session', 'session1');

        var session = Omega.Session.restore_from_cookie();
        assert(session!= null);
        assert(session).isOfType(Omega.Session);
        assert(session.id).equals('session1');
        assert(session.user_id).equals('user1');
      });
    });

    it("returns null", function(){
      $.removeCookie('omega-user');
      $.removeCookie('omega-session');
      assert(Omega.Session.restore_from_cookie()).equals(null);
    });
  });

  describe("#login", function(){
    var user, node, cb;

    before(function(){
      user    = {};
      cb   = sinon.spy();

      node = new Omega.Node();
      stub = sinon.stub(node, 'http_invoke');
    });

    it("sets source_node header to id of user being logged in", function(){
      Omega.Session.login(user, node, cb)
      assert(node.http.headers['source_node']).equals(user.id);
    });

    it("invokes users::login http request", function(){
      Omega.Session.login(user, node, cb)
      assert(stub.getCall(0).args[0]).equals('users::login');
      assert(stub.getCall(0).args[1]).equals(user);
    });

    describe("successful response", function(){
      var response;
      var handler;

      before(function(){
        response = { error : null, result : { id : 'session1', user : { id : 'user1'} } };
        Omega.Session.login(user, node, cb);
        handler  = stub.getCall(0).args[2];
      });

      it("sets session headers on node", function(){
        handler.apply(null, [response]);
        assert(node.http.headers['session_id']).equals('session1')
        assert(node.http.headers['source_node']).equals('user1')
      });

      describe("callback specified", function(){
        it("invokes callback with session", function(){
          handler.apply(null, [response]);
          sinon.assert.called(cb);
          var session = cb.getCall(0).args[0];
          assert(session).isOfType(Omega.Session)
          assert(session.id).equals('session1')
          assert(session.user_id).equals('user1')
        });
      });

      it("raises login event", function(){
        var spy = sinon.spy();
        Omega.Session.addEventListener('login', spy);
        handler.apply(null, [response]);
        var session = cb.getCall(0).args[0];
        sinon.assert.calledWith(spy);
        assert(spy.getCall(0).args[0].data).equals(session);
      })
    });
  });

});}); // Session
