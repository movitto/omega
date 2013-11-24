pavlov.specify("Omega.JumpGate", function(){
describe("Omega.JumpGate", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = {gfx: Omega.JumpGate.gfx,
                mesh: Omega.JumpGate.gfx ? Omega.JumpGate.gfx.mesh : null};
      })

      after(function(){
        Omega.JumpGate.gfx = orig.gfx;
        if(Omega.JumpGate.gfx) Omega.JumpGate.gfx.mesh = orig.mesh;
      });

      it("does nothing / just returns", function(){
        Omega.JumpGate.gfx = {};
        Omega.JumpGate.mesh = null;
        new Omega.JumpGate().load_gfx();
        assert(Omega.JumpGate.mesh).isNull();
      });
    });

    it("creates mesh for JumpGate", async(function(){
      var jg = Omega.Test.Canvas.Entities().jump_gate;
      jg.retrieve_resource('mesh', function(){
        assert(Omega.JumpGate.gfx.mesh).isOfType(THREE.Mesh);
        assert(Omega.JumpGate.gfx.mesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.JumpGate.gfx.mesh.geometry).isOfType(THREE.Geometry);
        /// TODO assert material texture & geometry src path values ?
        start();
      });
    }));

    it("creates lamp for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.lamp).isOfType(THREE.Mesh);
      assert(Omega.JumpGate.gfx.lamp.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.JumpGate.gfx.lamp.geometry).isOfType(THREE.SphereGeometry);
    });

    it("creates particle system for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.particles).isOfType(THREE.ParticleSystem);
      assert(Omega.JumpGate.gfx.particles.material).isOfType(THREE.ParticleBasicMaterial);
      assert(Omega.JumpGate.gfx.particles.geometry).isOfType(THREE.Geometry);
    });

    it("creates selection sphere for JumpGate", function(){
      Omega.Test.Canvas.Entities();
      assert(Omega.JumpGate.gfx.selection_sphere).isOfType(THREE.Mesh);
      assert(Omega.JumpGate.gfx.selection_sphere.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.JumpGate.gfx.selection_sphere.geometry).isOfType(THREE.SphereGeometry);
    });
  });

  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.JumpGate.gfx){
        if(Omega.JumpGate.gfx.mesh && Omega.JumpGate.gfx.mesh.clone.restore) Omega.JumpGate.gfx.mesh.clone.restore();
        if(Omega.JumpGate.gfx.lamp.clone.restore) Omega.JumpGate.gfx.lamp.clone.restore();
        if(Omega.JumpGate.gfx.particles.clone.restore) Omega.JumpGate.gfx.particles.clone.restore();
        if(Omega.JumpGate.gfx.selection_sphere.clone.restore) Omega.JumpGate.gfx.selection_sphere.clone.restore();
      }
    });

    it("loads jump gate gfx", function(){
      var jg        = new Omega.JumpGate();
      var load_gfx  = sinon.spy(jg, 'load_gfx');
      jg.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones JumpGate mesh", async(function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.JumpGate.prototype.
        retrieve_resource('template_mesh', function(){
          sinon.stub(Omega.JumpGate.gfx.mesh, 'clone').returns(mesh);
        });

      var jg = new Omega.JumpGate();
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh).equals(mesh);
        start();
      });
    }));

    it("sets mesh position", async(function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh.position.x).equals(100);
        assert(jg.mesh.position.y).equals(-100);
        assert(jg.mesh.position.z).equals(200);
        start();
      });
    }));

    it("sets mesh.omega_entity", async(function(){
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      jg.retrieve_resource('mesh', function(){
        assert(jg.mesh.omega_entity).equals(jg);
        start();
      });
    }));

    it("clones JumpGate lamp", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.lamp, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.lamp).equals(mesh);
    });

    it("sets lamp position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.lamp.position.toArray()).isSameAs([100, -100, 200])
    });

    it("clones JumpGate particles", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.particles, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.particles).equals(mesh);
    });

    it("sets particles position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.particles.position.toArray()).isSameAs([70, -125, 275]);
    });

    it("clones JumpGate selection sphere", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.JumpGate.gfx.selection_sphere, 'clone').returns(mesh);
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.selection_sphere).equals(mesh);
    });

    it("sets selection sphere position", function(){
      var jg = new Omega.JumpGate({location : new Omega.Location({x: 100, y: -100, z: 200})});
      jg.init_gfx();
      assert(jg.selection_sphere.position.toArray()).isSameAs([80, -100, 200]);
    });

    /// it("sets selection sphere radius") NIY

    it("adds mesh, lamp, particles, and selection sphere to jump gate scene components", function(){
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      assert(jg.components).isSameAs([jg.mesh, jg.lamp, jg.particles, jg.selection_sphere]);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      Omega.Test.Canvas.Entities();
      var jg = new Omega.JumpGate({});
      jg.init_gfx();
      var run_effects = sinon.spy(jg.lamp, 'run_effects');
      jg.run_effects();
      sinon.assert.called(run_effects);
    });

    //it("updates particles") // NIY
  });

});}); // Omega.JumpGate
