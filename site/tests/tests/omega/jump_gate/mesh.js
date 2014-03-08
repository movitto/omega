pavlov.specify("Omega.JumpGateMesh", function(){
describe("Omega.JumpGateMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var gate_mesh = new Omega.JumpGateMesh({mesh: tmesh});
    assert(gate_mesh.tmesh).equals(tmesh);
  });

  //describe("#load_template", function(){}); // NIY
  //describe("#load", function(){}); // NIY
});});
