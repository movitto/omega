pavlov.specify("Omega.StationMesh", function(){
describe("Omega.StationMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var mesh = new Omega.StationMesh({mesh : tmesh});
    assert(mesh.tmesh).equals(tmesh);
  });
});}); // Omega.StationMesh

