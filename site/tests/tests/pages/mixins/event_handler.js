pavlov.specify("Omega.Pages.EventHandler", function(){
describe("Omega.Pages.EventHandler", function(){
  describe("#handle_events", function(){
    var index;
    before(function(){
      index = new Omega.Pages.Index();
    });

    it("tracks all motel and manufactured events", function(){
      var events = Omega.CallbackHandler.all_events();
      sinon.stub(index.callback_handler, 'track');
      index._handle_events();
      for(var e = 0; e < events.length; e++)
        sinon.assert.calledWith(index.callback_handler.track, events[e]);
    });
  });
});});
