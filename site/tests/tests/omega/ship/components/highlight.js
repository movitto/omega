pavlov.specify("Omega.ShipHighlightEffects", function(){
describe("Omega.ShipHighlightEffects", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var highlight = new Omega.ShipHighlightEffects({mesh : tmesh});
    assert(highlight.mesh).equals(tmesh);
  });
});}); // Omega.ShipHighlightEffects
