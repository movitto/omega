pavlov.specify("Omega.Node", function(){
describe("Omega.Node", function(){
  var node;

  before(function(){
    node = new Omega.Node();
    /// TODO stub out actual calls to server
  });

  after(function(){
  })

  it("creates a rjr ws node", function(){
    assert(node.ws).isOfType(RJR.WsNode);
  })

  it("creates a rjr web node", function(){
    assert(node.http).isOfType(RJR.HttpNode);
  })

  describe("ws message received", function(){
    it("raises msg_received event", function(){
      var spy = sinon.spy();
      node.addEventListener('msg_received', spy)

      var msg = { 'test' : 'msg' }
      node.ws.message_received(msg)
      sinon.assert.calledWith(spy, msg);
    });

    describe("request message", function(){
      it("invokes rpc method handlers", function(){
        var test = sinon.spy();
        var tset = sinon.spy();
        node.addEventListener('test', test);
        node.addEventListener('tset', tset);

        var msg = { 'rpc_method' : 'test', 'params' : ['p1', 'p2'] }
        node.ws.message_received(msg)
        sinon.assert.called(test);
        assert(test.getCall(0).args[0].data == ['p1', 'p2']);
        sinon.assert.notCalled(tset);
      });
    });
  });

  describe("http message received", function(){
    it("raises msg_received event", function(){
      var spy = sinon.spy();
      node.addEventListener('msg_received', spy);

      var msg = { 'test' : 'msg' }
      node.http.message_received(msg)
      sinon.assert.calledWith(spy, msg);
    });
  });

  describe("http node error", function(){
    it("invokes error handlers", function(){
      var spy = sinon.spy();
      node.addEventListener('error', spy);

      var err = 'err';
      node.http.onerror(err)
      sinon.assert.called(spy);
      assert(spy.getCall(0).args[0].data == err);
    });

    describe("http node connection error", function(){
      it("sets error.disconnected to true", function(){
        var spy = sinon.spy();
        node.addEventListener('error', spy);

        var err = {error : {code : 503, class : 'Service Unavailable'}};
        node.http.onerror(err)
        sinon.assert.called(spy);
        assert(spy.getCall(0).args[0].disconnected).isTrue();
      })
    })
  });

  describe("ws node error", function(){
    it("invokes error handlers", function(){
      var spy = sinon.spy();
      node.addEventListener('error', spy);

      var err = 'err';
      node.ws.onerror(err)
      sinon.assert.called(spy);
      assert(spy.getCall(0).args[0].data == err);
    });
  });

  describe("ws node closed", function(){
    it("raises closed event on node", function(){
      var spy = sinon.spy();
      node.addEventListener('closed', spy);
      node.ws.onclose()
      sinon.assert.called(spy);
    });
  })

  describe("#ws_invoke", function(){
    var invoke_stub;

    before(function(){
      invoke_stub = sinon.stub(node.ws, 'invoke');
    });

    it("opens ws connection on first request", function(){
      var open_stub = sinon.stub(node.ws, 'open');

      node.ws.opened = false
      node.ws_invoke();
      sinon.assert.calledWith(open_stub);

      open_stub.reset();
      node.ws.opened = true;
      node.ws_invoke();
      sinon.assert.notCalled(open_stub);
    });

    it("uses rjr ws node to invoke request", function(){
      node.ws_invoke('method', 'param');
      sinon.assert.calledWith(invoke_stub, 'method', 'param')
    });

    it("raises 'request' event", function(){
      var spy = sinon.spy();
      node.addEventListener('request', spy);

      invoke_stub.returns('msg');
      node.ws_invoke();
      sinon.assert.called(spy);
      assert(spy.getCall(0).args[0].data == 'msg')
    });
  })

  describe("#http_invoke", function(){
    var invoke_stub;

    before(function(){
      invoke_stub = sinon.stub(node.http, 'invoke');
    });

    it("uses rjr web node to invoke request", function(){
      node.http_invoke('method', 'param');
      sinon.assert.calledWith(invoke_stub, 'method', 'param');
    });

    it("raises 'request' event", function(){
      var spy = sinon.spy();
      node.addEventListener('request', spy);

      invoke_stub.returns('msg');
      node.http_invoke();
      sinon.assert.called(spy);
      assert(spy.getCall(0).args[0].data == 'msg')
    });
  })

  describe("#set_header", function(){
    it("sets header on web node", function(){
      node.set_header('test', 'value');
      assert(node.http.headers['test']).equals('value')
    });

    it("sets header on ws node", function(){
      node.set_header('test', 'value');
      assert(node.ws.headers['test']).equals('value')
    });
  });

});}); // Node
