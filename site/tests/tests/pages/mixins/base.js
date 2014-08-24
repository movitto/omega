pavlov.specify("Omega.Pages.Base", function(){
describe("Omega.Pages.Base", function(){
  var base;

  before(function(){
    base = $.extend({}, Omega.Pages.Base);
  });

  describe("#init_page", function(){
    it("creates page node", function(){
      base.init_page();
      assert(base.node).isOfType(Omega.Node);
    });
  });
});});
