pavlov.specify("Omega.Ship", function(){
describe("Omega.Ship", function(){
  describe("#owned_by", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Ship.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'owned_by', 'user1');
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new ship instances", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id: 'sh1'},{id: 'sh2'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(2);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
        assert(ships[1]).isOfType(Omega.Ship);
        assert(ships[1].id).equals('sh2');
      });
    });
  });
});}); // Omega.Galaxy
