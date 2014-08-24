pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  describe("#unload", function(){
    it("sets unloading true", function(){
      assert(page.unloading).isUndefined();
      page.unload();
      assert(page.unloading).isTrue();
    });

    it("closes node", function(){
      sinon.stub(page.node, 'close');
      page.unload();
      sinon.assert.called(page.node.close);
    })
  });
});});
