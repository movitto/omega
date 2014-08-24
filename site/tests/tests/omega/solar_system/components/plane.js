pavlov.specify("Omega.SolarSystemPlane", function(){
describe("Omega.SolarSystemPlane", function(){
  it("has a THREE.Mesh instance", function(){
    var system_plane = new Omega.SolarSystemPlane({});
    assert(system_plane.tmesh).isOfType(THREE.Mesh);
    assert(system_plane.tmesh.geometry).isOfType(THREE.PlaneGeometry);
    assert(system_plane.tmesh.material).isOfType(THREE.MeshBasicMaterial);
  });
});});
