pavlov.specify("Omega.Pages.Index", function(){
describe("Omega.Pages.Index", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Index();
  });

  // base page mixin test
  it("has a node", function(){
    assert(page.node).isOfType(Omega.Node);
  });

  // canvas mixin tests
  it("has a canvas", function(){
    assert(page.canvas).isOfType(Omega.UI.Canvas);
  });

  it("has an effects player", function(){
    assert(page.effects_player).isOfType(Omega.UI.EffectsPlayer);
    assert(page.effects_player.page).equals(page);
  });

  // audio mixin tests
  it("has audio controls", function(){
    assert(page.audio_controls).isOfType(Omega.UI.AudioControls);
  });
});});
