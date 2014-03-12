/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfx", function(){
describe("Omega.JumpGateGfx", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.location.set(100, -100, 200);
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig_gfx;

      before(function(){
        orig_gfx = Omega.JumpGate.gfx;
        Omega.JumpGate.gfx = null;
        sinon.stub(jg, 'gfx_loaded').returns(true);
      })

      after(function(){
        Omega.JumpGate.gfx = orig_gfx;
      });

      it("does nothing / just returns", function(){
        jg.load_gfx();
        assert(Omega.JumpGate.gfx).isNull();
      });
    });

    it("creates mesh for JumpGate", function(){
      assert(Omega.JumpGate.gfx.mesh).isOfType(Omega.JumpGateMesh);
    });

    it("creates lamp for JumpGate", function(){
      assert(Omega.JumpGate.gfx.lamp).isOfType(Omega.JumpGateLamp);
    });

    it("creates particle system for JumpGate", function(){
      assert(Omega.JumpGate.gfx.particles).isOfType(Omega.JumpGateParticles);
    });

    it("creates selection material for JumpGate", function(){
      assert(Omega.JumpGate.gfx.selection_material).
        isOfType(Omega.JumpGateSelectionMaterial);
    });
  });

  describe("#init_gfx", function(){
    after(function(){
      if(Omega.JumpGate.gfx.mesh.clone.restore)
        Omega.JumpGate.gfx.mesh.clone.restore();

      if(Omega.JumpGate.gfx.lamp.clone.restore)
        Omega.JumpGate.gfx.lamp.clone.restore();

      if(Omega.JumpGate.gfx.particles.clone.restore)
        Omega.JumpGate.gfx.particles.clone.restore();
    });

    it("loads jump gate gfx", function(){
      sinon.spy(jg, 'load_gfx');
      jg.init_gfx(Omega.Config);
      sinon.assert.called(jg.load_gfx);
    });

    it("clones JumpGate mesh", function(){
      var mesh = new Omega.JumpGateMesh({mesh: new THREE.Mesh()});
      sinon.stub(Omega.JumpGate.gfx.mesh, 'clone').returns(mesh);
      jg.init_gfx(Omega.Config);
      assert(jg.mesh).equals(mesh);
    });

    it("sets mesh position", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.mesh.tmesh.position.x).equals(100);
      assert(jg.mesh.tmesh.position.y).equals(-100);
      assert(jg.mesh.tmesh.position.z).equals(200);
    });

    it("sets mesh.omega_entity", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.mesh.omega_entity).equals(jg);
    });

    it("adds mesh to components", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.components).includes(jg.mesh.tmesh);
    });

    it("adds lamp to mesh", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.mesh.tmesh.getDescendants()).
        includes(jg.lamp.olamp.component);
    });

    it("clones JumpGate lamp", function(){
      var lamp = new Omega.JumpGateLamp();
      sinon.stub(Omega.JumpGate.gfx.lamp, 'clone').returns(lamp);
      jg.init_gfx(Omega.Config);
      assert(jg.lamp).equals(lamp);
    });

    it("sets lamp position", function(){
      var offset = Omega.JumpGateLamp.prototype.offset;
      jg.init_gfx(Omega.Config);
      assert(jg.lamp.olamp.component.position.toArray()).
        isSameAs([offset[0],
                  offset[1],
                  offset[2]])
    });

    it("clones JumpGate particles", function(){
      var mesh = new Omega.JumpGateParticles({config: Omega.Config});
      sinon.stub(Omega.JumpGate.gfx.particles, 'clone').returns(mesh);
      jg.init_gfx(Omega.Config);
      assert(jg.particles).equals(mesh);
    });

    it("sets particles position", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.particles.particles.emitters[0].position.toArray()).
        isSameAs([100, -100, 275]);
    });

    it("creates a selection sphere for jg", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.selection).isOfType(Omega.JumpGateSelection);
    });

    it("sets selection sphere position", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.selection.tmesh.position.toArray()).
        isSameAs([0,0,0]);
    });

    /// it("sets selection sphere radius") NIY

    it("adds particles to jump gate scene components", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.components).includes(jg.particles.particles.mesh);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      Omega.Test.Canvas.Entities();
      var jg = new Omega.JumpGate({});
      jg.init_gfx(Omega.Config);
      var run_effects = sinon.spy(jg.lamp, 'run_effects');
      jg.run_effects();
      sinon.assert.called(run_effects);
    });

    //it("updates particles") // NIY
  });
});});
