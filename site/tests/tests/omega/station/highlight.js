pavlov.specify("Omega.StationHighlightEffects", function(){
describe("Omega.StationHighlightEffects", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var highlight = new Omega.StationHighlightEffects({mesh : tmesh});
    assert(highlight.mesh).equals(tmesh);
  });
});}); // Omega.StationHighlightEffects

