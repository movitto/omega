pavlov.specify("Omega.StarGfxLoader", function(){
describe("Omega.StarGfxLoader", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        var star = new Omega.Star();
        sinon.stub(star, 'gfx_loaded').returns(true);
        sinon.spy(star, '_loaded_gfx');
        star.load_gfx();
        sinon.assert.notCalled(star._loaded_gfx);
      });
    });

    it("creates mesh for Star", function(){
      var star = Omega.Test.entities()['star'];
      var mesh = star._retrieve_resource('mesh');
      assert(mesh).isOfType(Omega.StarMesh);
      assert(mesh.tmesh.geometry).isOfType(THREE.SphereGeometry);
      assert(mesh.tmesh.material).isOfType(THREE.MeshBasicMaterial);
    });

    it("creates light for Star", function(){
      var star  = Omega.Test.entities()['star'];
      var light = star.light;
      assert(light).isOfType(THREE.PointLight);
    });
  });
});});
