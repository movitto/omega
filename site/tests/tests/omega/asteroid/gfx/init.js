pavlov.specify("Omega.AsteroidGfxInitializer", function(){
describe("Omega.AsteroidGfxInitializer", function(){
  describe("#init_gfx", function(){
    it("loads asteroid gfx", function(){
      var ast      = Omega.Gen.asteroid();
      var load_gfx = sinon.spy(ast, 'load_gfx');
      ast.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("retrieves Asteroid geometry and creates mesh", function(){
      var ast = Omega.Gen.asteroid();
      var geos = ast._retrieve_async_resource('asteroid.meshes');
      sinon.stub(ast, '_retrieve_async_resource');
      ast.init_gfx();
      sinon.assert.calledWith(ast._retrieve_async_resource, 'asteroid.meshes', sinon.match.func);
      ast._retrieve_async_resource.omega_callback()(geos);
      assert(ast.mesh).isOfType(Omega.AsteroidMesh);
      assert(ast.mesh.tmesh.material).equals(ast._retrieve_resource('mesh_material').material);
      assert(geos).includes(ast.mesh.tmesh.geometry);
    });

    it("sets position tracker position", function(){
      var loc = new Omega.Location({x: 100, y: -100, z: 200});
      var ast = new Omega.Asteroid({location : loc});
      ast.init_gfx();
      assert(ast.position_tracker().position.x).equals(100);
      assert(ast.position_tracker().position.y).equals(-100);
      assert(ast.position_tracker().position.z).equals(200);
    });

    it("sets mesh.omega_entity", function(){
      var ast = Omega.Gen.asteroid();
      ast.init_gfx();
      assert(ast.mesh.omega_entity).equals(ast);
    });

    it("adds position tracker to asteroid scene components", function(){
      var ast = Omega.Gen.asteroid();
      ast.init_gfx();
      assert(ast.components).isSameAs([ast.position_tracker()]);
    });
  });
});});
