pavlov.specify("Omega.SolarSystemMesh", function(){
describe("Omega.SolarSystemMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var system_mesh = new Omega.SolarSystemMesh();
    assert(system_mesh.tmesh).isOfType(THREE.Mesh);
    assert(system_mesh.tmesh.geometry).isOfType(THREE.SphereGeometry);
    assert(system_mesh.tmesh.material).isOfType(THREE.MeshBasicMaterial);
  });
});});
