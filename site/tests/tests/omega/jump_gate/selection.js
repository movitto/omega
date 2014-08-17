pavlov.specify("Omega.JumpGateSelection", function(){
describe("Omega.JumpGateSelection", function(){
  it("has a THREE.Mesh instance", function(){
    var material = new THREE.MeshBasicMaterial();
    var gate_selection = new Omega.JumpGateSelection({size : 10,
                                                      material : material});
    assert(gate_selection.tmesh).isOfType(THREE.Mesh);
    assert(gate_selection.tmesh.geometry).isOfType(THREE.SphereGeometry);
    assert(gate_selection.tmesh.material).equals(material);
  });
});});
