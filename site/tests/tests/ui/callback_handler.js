pavlov.specify("Omega.UI.CallbackHandler", function(){
describe("Omega.UI.CallbackHandler", function(){
  describe("#track", function(){
    var handler;

    before(function(){
      handler = $.extend({_msg_received : sinon.spy()}, Omega.UI.CallbackHandler);
      handler.init_handlers();
      handler.page = new Omega.Pages.Test();
    });

    describe("event handler already registered", function(){
      it("does nothing / just returns", function(){
        handler.track("motel::on_rotation");
        assert(handler.page.node._listeners['motel::on_rotation'].length).equals(1);
        handler.track("motel::on_rotation");
        assert(handler.page.node._listeners['motel::on_rotation'].length).equals(1);
      });
    });

    it("adds new node event handler for event", function(){
      sinon.spy(handler.page.node, 'addEventListener');
      handler.track("motel::on_rotation");
      sinon.assert.calledWith(handler.page.node.addEventListener, 'motel::on_rotation', sinon.match.func);
    });

    describe("on event", function(){
      it("invokes _msg_received", function(){
        handler.track("motel::on_rotation");
        handler.page.node._listeners['motel::on_rotation'][0]({data : ['event_occurred']});
        sinon.assert.calledWith(handler._msg_received, 'motel::on_rotation', ['event_occurred']);
      });
    });
  }); 
});});
