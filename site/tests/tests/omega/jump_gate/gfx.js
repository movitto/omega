/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfx", function(){
describe("Omega.JumpGateGfx", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.location.set(100, -100, 200);
  });

  describe("#load_gfx", function(){
    var orig_gfx;

    before(function(){
      orig_gfx = Omega.JumpGate.gfx;
    });

    after(function(){
      Omega.JumpGate.gfx = orig_gfx;
    });

    describe("graphics are loaded", function(){
      before(function(){
        Omega.JumpGate.gfx = null;
        sinon.stub(jg, 'gfx_loaded').returns(true);
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

    it("creates audio effect for JumpGate triggering", function(){
      assert(Omega.JumpGate.gfx.trigger_audio).
        isOfType(Omega.JumpGateTriggerAudioEffect);
    });

    it("invokes _loaded_gfx", function(){
      sinon.stub(jg, 'gfx_loaded').returns(false);
      sinon.stub(jg, '_loaded_gfx');
      jg.load_gfx(Omega.Config);
      sinon.assert.called(jg._loaded_gfx);
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

    it("sets position tracker position", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.position_tracker().position.x).equals(100);
      assert(jg.position_tracker().position.y).equals(-100);
      assert(jg.position_tracker().position.z).equals(200);
    });

    it("sets mesh.omega_entity", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.mesh.omega_entity).equals(jg);
    });

    it("adds mesh to position tracker", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.position_tracker().getDescendants()).includes(jg.mesh.tmesh);
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

    it("creates local reference to jump gate triggering audio", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.trigger_audio).equals(Omega.JumpGate.gfx.trigger_audio);
    });

    /// it("sets selection sphere radius") NIY

    it("adds particles and position tracker to jump gate scene components", function(){
      jg.init_gfx(Omega.Config);
      assert(jg.components).includes(jg.particles.particles.mesh);
      assert(jg.components).includes(jg.position_tracker());
    });

    it("updates gfx", function(){
      sinon.spy(jg, 'update_gfx');
      jg.init_gfx(Omega.Config);
      sinon.assert.called(jg.update_gfx);
    });
  });

  describe("#update_gfx", function(){
    it("updates position tracker location using scene location", function(){
      jg.init_gfx(Omega.Config);
      jg.update_gfx();

      var pos = jg.position_tracker().position;
      assert(pos.x).equals( 100);
      assert(pos.y).equals(-100);
      assert(pos.z).equals( 200);
    });

    it("updates particles", function(){
      jg.init_gfx(Omega.Config);
      sinon.stub(jg.particles, 'update');
      jg.update_gfx();
      sinon.assert.called(jg.particles.update);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      jg.init_gfx(Omega.Config);
      sinon.spy(jg.lamp, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.lamp.run_effects);
    });

    it("runs particles effects", function(){
      jg.init_gfx(Omega.Config);
      sinon.spy(jg.particles, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.particles.run_effects);
    });

    it("runs mesh effects", function(){
      jg.init_gfx(Omega.Config);
      sinon.spy(jg.mesh, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.mesh.run_effects);
    });
  });
});});
