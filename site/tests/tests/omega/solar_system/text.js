pavlov.specify("Omega.SolarSystemText", function(){
describe("Omega.SolarSystemText", function(){
  it("has a THREE.Mesh instance", function(){
    var system_text = new Omega.SolarSystemText("system1");
    assert(system_text.text).isOfType(THREE.Mesh);
    assert(system_text.text.geometry).isOfType(THREE.TextGeometry);
    assert(system_text.text.material).isOfType(THREE.MeshBasicMaterial);
  });
});});
