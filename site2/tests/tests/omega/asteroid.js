pavlov.specify("Omega.Asteroid", function(){
describe("Omega.Asteroid", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.Asteroid.gfx,
                mesh: Omega.Asteroid.gfx ? Omega.Asteroid.gfx.mesh : null};
      })

      after(function(){
        Omega.Asteroid.gfx = orig.gfx;
        if(Omega.Asteroid.gfx) Omega.Asteroid.gfx.mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.Asteroid.gfx = {};
        Omega.Asteroid.mesh = null;
        new Omega.Asteroid().load_gfx();
        assert(Omega.Asteroid.mesh).isNull();
      });
    });

    it("creates mesh for Asteroid", async(function(){
      var asteroid = Omega.Test.Canvas.Entities().asteroid;
      asteroid.retrieve_resource('mesh', function(){
        assert(Omega.Asteroid.gfx.mesh).isOfType(THREE.Mesh);
        assert(Omega.Asteroid.gfx.mesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.Asteroid.gfx.mesh.geometry).isOfType(THREE.Geometry);
        /// TODO assert material texture & geometry src path values ?
        start();
      });
    }));
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.Asteroid.gfx){
        if(Omega.Asteroid.gfx.mesh && Omega.Asteroid.gfx.mesh.clone.restore) Omega.Asteroid.gfx.mesh.clone.restore();
      }
    });

    it("loads asteroid gfx", function(){
      var ast        = new Omega.Asteroid();
      var load_gfx  = sinon.spy(ast, 'load_gfx');
      ast.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Asteroid mesh", async(function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.Asteroid.prototype.
        retrieve_resource('template_mesh', function(){
          sinon.stub(Omega.Asteroid.gfx.mesh, 'clone').returns(mesh);
        });

      var ast = new Omega.Asteroid();
      ast.init_gfx();
      ast.retrieve_resource('mesh', function(){
        assert(ast.mesh).equals(mesh);
        start();
      });
    }));

    it("sets mesh position", async(function(){
      var ast = new Omega.Asteroid({location : new Omega.Location({x: 100, y: -100, z: 200})});
      ast.init_gfx();
      ast.retrieve_resource('mesh', function(){
        assert(ast.mesh.position.x).equals(100);
        assert(ast.mesh.position.y).equals(-100);
        assert(ast.mesh.position.z).equals(200);
        start();
      });
    }));

    it("sets mesh.omega_entity", async(function(){
      var ast = new Omega.Asteroid({});
      ast.init_gfx();
      ast.retrieve_resource('mesh', function(){
        assert(ast.mesh.omega_entity).equals(ast);
        start();
      });
    }));

    it("adds mesh to asteroid scene components", async(function(){
      var ast = new Omega.Asteroid();
      ast.init_gfx();
      ast.retrieve_resource('mesh', function(){
        assert(ast.components).isSameAs([ast.mesh]);
        start();
      });
    }));
  });

});}); // Omega.Asteroid
