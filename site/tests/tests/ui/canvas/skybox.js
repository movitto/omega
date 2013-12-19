pavlov.specify("Omega.UI.CanvasSkybox", function(){
describe("Omega.UI.CanvasSkybox", function(){
  var orig;

  before(function(){
    orig = Omega.UI.CanvasSkybox.gfx;
  });

  after(function(){
    Omega.UI.CanvasSkybox.gfx = orig;
  });
  
  it("has the id: canvas_skybox", function(){
    var skybox = new Omega.UI.CanvasSkybox();
    assert(skybox.id).equals('canvas_skybox');
  })

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        Omega.UI.CanvasSkybox.gfx = {};
        new Omega.UI.CanvasSkybox().load_gfx();
        assert(Omega.UI.CanvasSkybox.gfx.mesh).isUndefined();
      });
    });

    it("creates mesh for skybox", function(){
      var canvas = Omega.Test.Canvas();
      assert(canvas.skybox.mesh).isOfType(THREE.Mesh);
      assert(canvas.skybox.mesh.geometry).isOfType(THREE.CubeGeometry);
      assert(canvas.skybox.mesh.material).isOfType(THREE.ShaderMaterial);
    });
  });

  describe("#init_gfx", function(){
    it("loads skybox gfx", function(){
      var skybox = new Omega.UI.CanvasSkybox();
      var load_gfx = sinon.spy(skybox, 'load_gfx');
      skybox.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("adds Skybox mesh to scene components", function(){
      var skybox = new Omega.UI.CanvasSkybox();
      skybox.init_gfx();
      assert(skybox.components[0]).equals(skybox.mesh);
    });
  });

  describe("#set", function(){
    it("sets mesh material to new background", function(){
      var skybox = new Omega.UI.CanvasSkybox({canvas: Omega.Test.Canvas()});
      skybox.init_gfx();
      var oldB = skybox.mesh.material.uniforms["tCube"].value;
      skybox.set('galaxy1');
      var newB = skybox.mesh.material.uniforms["tCube"].value;
      assert(oldB).isNotEqualTo(newB); // XXX should validate actual new value
    });
  });
});}); // Omega.UI.CanvasSkybox

