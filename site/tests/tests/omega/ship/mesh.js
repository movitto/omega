pavlov.specify("Omega.ShipMesh", function(){
describe("Omega.ShipMesh", function(){
  it("has a THREE.Mesh instance", function(){
    var tmesh = new THREE.Mesh();
    var mesh = new Omega.ShipMesh({mesh : tmesh});
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
      mesh = new Omega.ShipMesh({mesh : tmesh});
      mesh.omega_entity = { location : loc };
    });

    after(function(){
      if(Omega.set_rotation.restore) Omega.set_rotation.restore();
    });

    it("sets mesh position", function(){
      mesh.base_position = [10,20,-30];
      mesh.update();
      assert(mesh.tmesh.position.x).equals(loc.x + 10);
      assert(mesh.tmesh.position.y).equals(loc.y + 20);
      assert(mesh.tmesh.position.z).equals(loc.z - 30);
    });

    it("rotates mesh", function(){
      var rotate = sinon.spy(Omega, 'set_rotation');
      mesh.base_rotation = [0.01, 0.02, -0.03]
      mesh.update();
      sinon.assert.calledWith(rotate, mesh.tmesh);
      assert(rotate.getCall(0).args[1]).isSameAs(mesh.base_rotation);
      assert(rotate.getCall(1).args[1].elements).
        isSameAs(loc.rotation_matrix().elements);
    });
  });
});}); // Omega.ShipMesh

