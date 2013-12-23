pavlov.specify("Omega.Stat", function(){
describe("Omega.Stat", function(){
  describe("Stat#get", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke')
    });

    it("invokes stats::get to retrieve stat", function(){
      Omega.Stat.get('users_with_most', ['entities'], node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'stats::get', 'users_with_most', ['entities'], sinon.match.func);
    });

    describe("stats::get response", function(){
      it("invokes callback with converted stat", function(){
        var stat = {id : 'foo'};
        Omega.Stat.get('users_with_most', ['entities'], node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({result : stat});
        sinon.assert.called(retrieval_cb);
        var rstat = retrieval_cb.getCall(0).args[0];
        assert(rstat).isOfType(Omega.Stat);
        assert(rstat.id).equals('foo');
      });
    });
  });
});});
