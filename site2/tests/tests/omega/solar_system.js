pavlov.specify("Omega.SolarSystem", function(){
describe("Omega.SolarSystem", function(){
  describe("#with_id", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes cosmos::get_entity request", function(){
      Omega.SolarSystem.with_id('system1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'cosmos::get_entity', 'with_id', 'system1');
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.SolarSystem.with_id('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new system instance", function(){
        Omega.SolarSystem.with_id('system1', node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({result : {id:'sys1'}});
        var system = retrieval_cb.getCall(0).args[0];
        assert(system).isOfType(Omega.SolarSystem);
        assert(system.id).equals('sys1');
      });
    });
  });
});}); // Omega.SolarSystem
