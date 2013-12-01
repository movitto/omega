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
      Omega.Stat.get('with_most', ['entities'], node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'stats::get', 'with_most', ['entities'], sinon.match.func);
    });

    describe("stats::get response", function(){
      it("invokes callback with converted stats", function(){
        var stats = [{id : 'foo'}, {id : 'bar'}];
        Omega.Stat.get('with_most', ['entities'], node, retrieval_cb);
        invoke_spy.getCall(0).args[3]({result : stats});
        sinon.assert.called(retrieval_cb);
        var rstats = retrieval_cb.getCall(0).args[0];
        assert(rstats.length).equals(2);
        assert(rstats[0]).isOfType(Omega.Stat);
        assert(rstats[1]).isOfType(Omega.Stat);
        assert(rstats[0].id).equals('foo');
        assert(rstats[1].id).equals('bar');
      });
    });
  });
});});
