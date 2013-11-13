pavlov.specify("Omega.Star", function(){
describe("Omega.Star", function(){
  it("parses color into int", function(){
    var star = new Omega.Star({color: 'ABABAB'});
    assert(star.color_int).equals(0xABABAB);
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.Star.gfx,
                mesh: Omega.Star.gfx ? Omega.Star.gfx.mesh : null};
      })

      after(function(){
        Omega.Star.gfx = orig.gfx;
        if(Omega.Star.gfx) Omega.star.gfx.mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.Star.gfx = {};
        Omega.Star.mesh = null;
        new Omega.Star().load_gfx();
        assert(Omega.mesh.mesh).isNull();
      });
    });

    it("creates mesh for Star", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Star.gfx.mesh).isOfType(THREE.Mesh);
      assert(Omega.Star.gfx.mesh.geometry).isOfType(THREE.SphereGeometry);
      assert(Omega.Star.gfx.mesh.material).isOfType(THREE.ShaderMaterial);
    });

    it("creates glow for Star", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Star.gfx.glow).isOfType(THREE.Mesh);
      assert(Omega.Star.gfx.glow.geometry).isOfType(THREE.SphereGeometry);
      assert(Omega.Star.gfx.glow.material).isOfType(THREE.ShaderMaterial);
    });

    it("creates light for Star", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.Star.gfx.light).isOfType(THREE.PointLight);
    });
  });

  describe("#init_gfx", function(){
    after(function(){
      if(Omega.Star.gfx){
        if(Omega.Star.gfx.mesh.clone.restore) Omega.Star.gfx.mesh.clone.restore();
        if(Omega.Star.gfx.glow.clone.restore) Omega.Star.gfx.glow.clone.restore();
        if(Omega.Star.gfx.light.clone.restore) Omega.Star.gfx.light.clone.restore();
      }
    });

    it("loads star gfx", function(){
      var star      = new Omega.Star();
      var load_gfx  = sinon.spy(star, 'load_gfx');
      star.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Star mesh", function(){
      var star = new Omega.Star();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Star.gfx.mesh.clone).returns(mesh);
      star.init_gfx();
      assert(star.mesh).equals(mesh);
    });

    it("sets mesh position", function(){
      var star = new Omega.Star({location : new Location({x: 100, y: -100, z: 200});});
      star.init_gfx();
      assert(star.mesh.position.toArray()).equals(100, -100, 200);
    });

    /// it("sets mesh radius") NIY

    it("clones mesh for shader scene", function(){
      var star = new Omega.Star();
      var mesh = new THREE.Mesh();
      var shader_mesh = new THREE.Mesh();
      sinon.stub(Omega.Star.gfx.mesh.clone).returns(mesh);
      sinon.stub(mesh, 'clone').returns(shader_mesh);
      star.init_gfx();
      assert(star.shader_mesh).equals(shader_mesh);
    });

    it("clones Star glow", function(){
      var star = new Omega.Star();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Star.gfx.glow.clone).returns(mesh);
      star.init_gfx();
      assert(star.glow).equals(mesh);
    });

    it("sets glow position", function(){
      var star = new Omega.Star({location : new Location({x: 100, y: -100, z: 200});});
      star.init_gfx();
      assert(star.glow.position.toArray()).equals(100, -100, 200);
    });

    it("clones Star light", function(){
      var star = new Omega.Star();
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Star.gfx.light.clone).returns(mesh);
      star.init_gfx();
      assert(star.light).equals(mesh);
    });

    it("sets light position", function(){
      var star = new Omega.Star({location : new Location({x: 100, y: -100, z: 200});});
      star.init_gfx();
      assert(star.light.position.toArray()).equals(100, -100, 200);
    });

    it("sets light color", function(){
      var star = new Omega.Star({color: 'ABABCC'});
      star.init_gfx();
      assert(star.light.color.getHex()).equals(0xABABCC);
    });

    it("adds mesh and light to star scene components", function(){
      var star = new Omega.Star();
      star.init_gfx();
      assert(star.components).equals([star.mesh, star.light]);
    });

    it("adds shader mesh and glow to star shader scene components", function(){
      var star = new Omega.Star();
      star.init_gfx();
      assert(star.shader_components).equals([star.glow, star.shader_mesh]);
    });
  });

});}); // Omega.Star
