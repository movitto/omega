pavlov.specify("Omega.Pages.Stats", function(){
describe("Omega.Pages.Stats", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Stats();
  });

  it("initializes stats ", function(){
    assert(page.stat_results).isSameAs({});
  });
});});
