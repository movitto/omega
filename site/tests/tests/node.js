pavlov.specify("Node", function(){
describe("Node", function(){
  var node;

  before(function(){
    node = Node();
  });

  after(function(){
    if(node.raise_event.restore) node.raise_event.restore();
    if(WSNode.restore)  WSNode.restore();
    if(WebNode.restore) WebNode.restore();
  })

  describe("#add_handler", function(){
    it("adds handler to node", function(){
      var h = function(){};
      node.add_handler('test', h);
      assert(node.handlers['test'][0]).equals(h);
    });
  });

  describe("#clear_handlers", function(){
    it("clears all handlers for specified method", function(){
      node.add_handler('test', function(){});
      node.clear_handlers('test');
      assert(node.handlers['test'].length).equals(0);
    });
  });

  describe("#on_error", function(){
    it("adds error handler to node", function(){
      var h = function(){};
      node.on_error(h);
      assert(node.error_handlers[0]).equals(h);
    });
  });

  describe("#clear_error_handlers", function(){
    it("clears all error handlers for specified method", function(){
      node.on_error(function(){});
      node.clear_error_handlers();
      assert(node.error_handlers.length).equals(0);
    });
  });

  describe("ws message received", function(){
    var wsn;
    
    before(function(){
      wsn  = new WSNode();
      sinon.stub(window, 'WSNode').returns(wsn);

      // need to create node after stub above
      node = new Node();
    });

    it("raises msg_received event", function(){
      var spy = sinon.spy(node, 'raise_event')
      var msg = { 'test' : 'msg' }
      wsn.message_received(msg)
      sinon.assert.calledWith(spy, 'msg_received', msg);
    });

    describe("request message", function(){
      it("invokes rpc method handlers", function(){
        var h1 = sinon.spy();
        var h2 = sinon.spy();
        node.add_handler('test', h1);
        node.add_handler('tset', h2);

        var msg = { 'rpc_method' : 'test', 'params' : ['p1', 'p2'] }
        wsn.message_received(msg)
        sinon.assert.calledWith(h1, 'p1', 'p2');
      });
    });
  });

  describe("web message received", function(){
    it("raises msg_received event", function(){
      var wbn  = new WebNode();
      sinon.stub(window, 'WebNode').returns(wbn);
      node = new Node();

      var spy = sinon.spy(node, 'raise_event')
      var msg = { 'test' : 'msg' }
      wbn.message_received(msg)
      sinon.assert.calledWith(spy, 'msg_received', msg);
    });
  });

  describe("web node error", function(){
    it("invokes error handlers", function(){
      var wbn  = new WebNode();
      sinon.stub(window, 'WebNode').returns(wbn);
      node = new Node();

      var spy = sinon.spy();
      node.on_error(spy);

      var err = 'err';
      wbn.onerror(err)
      sinon.assert.calledWith(spy, 'err');
    });
  });

  describe("ws node error", function(){
    it("invokes error handlers", function(){
      var wsn  = new WSNode();
      sinon.stub(window, 'WSNode').returns(wsn);
      node = new Node();

      var spy = sinon.spy();
      node.on_error(spy);

      var err = 'err';
      wsn.onerror(err)
      sinon.assert.calledWith(spy, 'err');
    });
  });

  describe("#ws_request", function(){
    var wsn;
    var open_stub;
    var invoke_stub;

    before(function(){
      wsn  = new WSNode();
      sinon.stub(window, 'WSNode').returns(wsn);
      open_stub = sinon.stub(wsn, 'open');
      invoke_stub = sinon.stub(wsn, 'invoke');
      node = new Node();
    });

    it("opens ws connection on first request", function(){
      wsn.opened = false
      node.ws_request();
      sinon.assert.calledWith(open_stub);

      open_stub.reset();
      wsn.opened = true;
      node.ws_request();
      sinon.assert.notCalled(open_stub);
    });

    it("uses rjr ws node to invoke request", function(){
      node.ws_request('method', 'param');
      sinon.assert.calledWith(invoke_stub, 'method', 'param')
    });

    it("raises 'request' event", function(){
      var spy = sinon.spy(node, 'raise_event');
      invoke_stub.returns('msg')
      node.ws_request();
      sinon.assert.calledWith(spy, 'request', 'msg')
    });

    it("raises 'ws_request' event", function(){
      var spy = sinon.spy(node, 'raise_event');
      invoke_stub.returns('msg')
      node.ws_request();
      sinon.assert.calledWith(spy, 'ws_request', 'msg')
    });
  })

  describe("#web_request", function(){
    var wbn;
    var invoke_stub;

    before(function(){
      wbn  = new WebNode();
      sinon.stub(window, 'WebNode').returns(wbn);
      invoke_stub = sinon.stub(wbn, 'invoke');
      node = new Node();
    });

    it("uses rjr web node to invoke request", function(){
      node.web_request('method', 'param')
      sinon.assert.calledWith(invoke_stub, 'method', 'param');
    });

    it("raises 'request' event", function(){
      var spy = sinon.spy(node, 'raise_event');
      invoke_stub.returns('msg')
      node.web_request();
      sinon.assert.calledWith(spy, 'request', 'msg')
    });

    it("raises 'web_request' event", function(){
      var spy = sinon.spy(node, 'raise_event');
      invoke_stub.returns('msg')
      node.web_request();
      sinon.assert.calledWith(spy, 'web_request', 'msg')
    });
  })

  describe("#set_header", function(){
    it("sets header on web node", function(){
      var wbn  = new WebNode();
      sinon.stub(window, 'WebNode').returns(wbn);
      node = new Node();
      node.set_header('test', 'value');
      assert(wbn.headers['test']).equals('value')
    });

    it("sets header on ws node", function(){
      var wsn  = new WSNode();
      sinon.stub(window, 'WSNode').returns(wsn);
      node = new Node();
      node.set_header('test', 'value');
      assert(wsn.headers['test']).equals('value')
    });
  });

});}); // Node

pavlov.specify("Session", function(){
describe("Session", function(){
  var session;
  var node;

  before(function(){
    session = new Session({});
    node    = new Node();
  });

  after(function(){
    if($.cookie.restore) $.cookie.restore();
    if(node.set_header.restore) node.set_header.restore();
    if(node.web_request.restore) node.web_request.restore();
  })

  it("sets omega-session cookie", function(){
    sinon.spy($, 'cookie');
    var s = new Session({id : 'test'});
    assert($.cookie.getCall(0).args[0]).equals('omega-session');
    assert($.cookie.getCall(0).args[1]).equals('test');
  });

  it("sets omega-user cookie", function(){
    sinon.spy($, 'cookie');
    var s = new Session({user_id : 'test'});
    assert($.cookie.getCall(1).args[0]).equals('omega-user');
    assert($.cookie.getCall(1).args[1]).equals('test');
  });

  describe("#set_headers_on", function(){
    var spy;

    before(function(){
      spy = sinon.spy(node, 'set_header');
      session.id = 'test';
      session.user_id = 'test-user';
    });

    it('sets session_id header on node', function(){
      session.set_headers_on(node);
      assert(spy.getCall(0).args[0]).equals('session_id')
      assert(spy.getCall(0).args[1]).equals('test')
    });

    it('sets source_node header on node', function(){
      session.set_headers_on(node);
      assert(spy.getCall(1).args[0]).equals('source_node')
      assert(spy.getCall(1).args[1]).equals('test-user')
    });
  });
  
  describe("#clear_headers_on", function(){
    var spy;

    before(function(){
      spy = sinon.spy(node, 'set_header');
      session.id = 'test';
      session.user_id = 'test-user';
    });

    it("clears session_id header on node", function(){
      session.clear_headers_on(node);
      assert(spy.getCall(0).args[0]).equals('session_id')
      assert(spy.getCall(0).args[1]).equals(null);
    });
    it("clears source_node header on node", function(){
      session.clear_headers_on(node);
      assert(spy.getCall(1).args[0]).equals('source_node')
      assert(spy.getCall(1).args[1]).equals(null);
    });
  });

  describe("#validate", function(){
    it("validates session via web request", function(){
      var cb  = function() {};
      var stub = sinon.stub(node, 'web_request');
      session.validate(node, cb);
      assert(stub.getCall(0).args[0]).equals('users::get_entity');
      assert(stub.getCall(0).args[3]).equals(cb);
    });
  });

  describe("#destroy", function(){
    var spy;

    before(function(){
      sinon.spy($, 'cookie');
    });

    it("clears omega-session cookie", function(){
      session.destroy();
      assert($.cookie.getCall(0).args[0]).equals('omega-session');
      assert($.cookie.getCall(0).args[1]).equals(null);
    });

    it("clears omega-user cookie", function(){
      session.destroy();
      assert($.cookie.getCall(1).args[0]).equals('omega-user');
      assert($.cookie.getCall(1).args[1]).equals(null);
    });
  });

  describe("#restore_from_cookie", function(){
    var spy;

    it("reads omega-user cookie", function(){
      sinon.spy($, 'cookie');
      Session.restore_from_cookie();
      assert($.cookie.getCall(0).args[0]).equals('omega-user');
    });

    it("reads omega-session cookie", function(){
      sinon.spy($, 'cookie');
      Session.restore_from_cookie();
      assert($.cookie.getCall(1).args[0]).equals('omega-session');
    });

    describe("user and session not null", function(){
      it("instantiates Session.current_session", function(){
        sinon.stub($, 'cookie').returns('test');
        assert(Session.current_session == null);
        Session.restore_from_cookie();
        assert(Session.current_session != null);
        assert(Session.current_session.id).equals('test');
        assert(Session.current_session.user_id).equals('test');
      });

      it("returns Session.current_session", function(){
        sinon.stub($, 'cookie').returns('test');
        assert(Session.restore_from_cookie()).equals(Session.current_session);
      });
    });

    it("returns null", function(){
      sinon.stub($, 'cookie').returns(null);
      assert(Session.restore_from_cookie()).equals(null);
    });
  });

  describe("#login", function(){
    var user, cb, stub;

    before(function(){
      u    = {};
      cb   = sinon.spy();
      stub = sinon.stub(node, 'web_request');
    });

    it("invokes users::login web request", function(){
      Session.login(u, node, cb)
      assert(stub.getCall(0).args[0]).equals('users::login');
      assert(stub.getCall(0).args[1]).equals(u);
    });

    describe("successful response", function(){
      var response;
      var handler;

      before(function(){
        response = { error : null, result : { id : 'test', user : { id : 'test_user'} } };
        Session.login(u, node, cb);
        handler  = stub.getCall(0).args[2];
      });

      it("instantiates Session.current_session", function(){
        handler.apply(null, [response]);
        assert(Session.current_session != null);
        assert(Session.current_session.id).equals('test');
        assert(Session.current_session.user_id).equals('test_user');
      });

      it("sets session headers on node", function(){
        var spy = sinon.spy(node, 'set_header')
        handler.apply(null, [response]);
        sinon.assert.calledWith(spy, 'session_id', 'test');
        sinon.assert.calledWith(spy, 'source_node', 'test_user');
      });

      describe("callback specified", function(){
        it("invokes callback with session", function(){
          handler.apply(null, [response]);
          sinon.assert.calledWith(cb, Session.current_session);
        });
      });
    });
  });

  describe("#logout", function(){
    var cb, stub;

    before(function(){
      Session.current_session = new Session({id : 'test'})
      cb   = sinon.spy();
      stub = sinon.stub(node, 'web_request');
    });

    it("invokes users::logout web request", function(){
      Session.logout(node, cb)
      assert(stub.getCall(0).args[0]).equals('users::logout');
      assert(stub.getCall(0).args[1]).equals('test');
    });

    describe("logout response handler", function(){
      var response;
      var handler;

      before(function(){
        Session.logout(node, cb)
        handler  = stub.getCall(0).args[2];
      });

      it("clears Session.current_session headers on node", function(){
        var spy = sinon.spy(Session.current_session, 'clear_headers_on')
        handler(response);
        sinon.assert.calledWith(spy, node);
      });

      it("sets Session.current_session null", function(){
        handler(response);
        assert(Session.current_session).equals(null);
      });

      describe("callback specified", function(){
        it("invokes callback", function(){
          handler(response)
          sinon.assert.called(cb)
        });
      });
    });
  });
});}); // Session
