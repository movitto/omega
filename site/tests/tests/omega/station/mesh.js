pavlov.specify("Omega.StationMesh", function(){
describe("Omega.StationMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var mesh = new Omega.StationMesh({mesh : tmesh});
    assert(mesh.tmesh).equals(tmesh);
  });

  describe("#update", function(){
    var loc, mesh;

    before(function(){
      loc = new Omega.Location({x : 200, y : -200, z: 50,
                                orientation_x : 0,
                                orientation_y : 0,
                                orientation_z : 1});

      var tmesh = new THREE.Mesh();
      mesh = new Omega.StationMesh({mesh : tmesh});
      mesh.omega_entity = { location : loc };
    });

    after(function(){
      if(Omega.set_rotation.restore) Omega.set_rotation.restore();
    });

    it("sets mesh position", function(){
      mesh.base_position = [10,20,-30];
      mesh.update();
      assert(mesh.tmesh.position.x).equals(loc.x);
      assert(mesh.tmesh.position.y).equals(loc.y);
      assert(mesh.tmesh.position.z).equals(loc.z);
    });
  });
});}); // Omega.StationMesh

