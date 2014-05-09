pavlov.specify("Omega.ShipMesh", function(){
describe("Omega.ShipMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var mesh = new Omega.ShipMesh({mesh : tmesh});
    assert(mesh.tmesh).equals(tmesh);
  });
});}); // Omega.ShipMesh

