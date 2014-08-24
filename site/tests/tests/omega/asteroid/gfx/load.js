pavlov.specify("Omega.AsteroidGfxLoader", function(){
describe("Omega.AsteroidGfxLoader", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        var asteroid = new Omega.Asteroid();
        sinon.stub(asteroid, 'gfx_loaded').returns(true);
        sinon.spy(asteroid, '_loaded_gfx');
        asteroid.load_gfx();
        sinon.assert.notCalled(asteroid._loaded_gfx);
      });
    });

    it("loads Asteroid mesh geometries", function(){
      var event_cb  = function(){};
      var mesh_geos = Omega.AsteroidMesh.geometry_paths();
      var asteroid = new Omega.Asteroid();
      sinon.stub(asteroid, 'gfx_loaded').returns(false);
      sinon.stub(asteroid, '_load_async_resource');
      asteroid.load_gfx(event_cb);
      sinon.assert.calledWith(asteroid._load_async_resource, 'asteroid.meshes', mesh_geos, event_cb);
    });
  });
});});
