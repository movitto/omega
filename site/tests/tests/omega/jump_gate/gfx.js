/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfx", function(){
describe("Omega.JumpGateGfx", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.location.set(100, -100, 200);
  });

  describe("#load_gfx", function(){
    describe("graphics are loaded", function(){
      it("does nothing / just returns", function(){
        sinon.stub(jg, 'gfx_loaded').returns(true);
        sinon.spy(jg, '_loaded_gfx');
        jg.load_gfx();
        sinon.assert.notCalled(jg._loaded_gfx);
      });
    });

    it("loads JumpGate mesh geometry ", function(){
      var event_cb = function(){};
      var mesh_geo = Omega.JumpGateMesh.geometry();
      sinon.stub(jg, 'gfx_loaded').returns(false);
      sinon.stub(jg, '_load_async_resource');
      jg.load_gfx(event_cb);
      sinon.assert.calledWith(jg._load_async_resource, 'jump_gate.geometry', mesh_geo, event_cb);
    });

    it("creates mesh material for JumpGate", function(){
      var jg  = Omega.Test.Canvas.Entities()['jump_gate'];
      var mat = jg._retrieve_resource('mesh_material');
      assert(mat).isOfType(Omega.JumpGateMeshMaterial);
    });

    it("creates lamp for JumpGate", function(){
      var jg   = Omega.Test.Canvas.Entities()['jump_gate'];
      var lamp = jg._retrieve_resource('lamp');
      assert(lamp).isOfType(Omega.JumpGateLamp);
    });

    it("creates particle system for JumpGate", function(){
      var jg = Omega.Test.Canvas.Entities()['jump_gate'];
      var particles = jg._retrieve_resource('particles');
      assert(particles).isOfType(Omega.JumpGateParticles);
    });

    it("creates selection material for JumpGate", function(){
      var jg  = Omega.Test.Canvas.Entities()['jump_gate'];
      var mat = jg._retrieve_resource('selection_material');
      assert(mat).isOfType(Omega.JumpGateSelectionMaterial);
    });

    it("creates audio effect for JumpGate triggering", function(){
      var jg    = Omega.Test.Canvas.Entities()['jump_gate'];
      var audio = jg._retrieve_resource('trigger_audio');
      assert(audio).isOfType(Omega.JumpGateTriggerAudioEffect);
    });

    it("invokes _loaded_gfx", function(){
      sinon.stub(jg, 'gfx_loaded').returns(false);
      sinon.stub(jg, '_loaded_gfx');
      jg.load_gfx();
      sinon.assert.called(jg._loaded_gfx);
    });
  });

  describe("#init_gfx", function(){
    var geo, lamp, particles;
    before(function(){
      geo = new THREE.Geometry();
      lamp = new Omega.JumpGateLamp();
      particles = new Omega.JumpGateParticles();
      sinon.stub(jg, '_retrieve_async_resource');
      sinon.stub(jg._retrieve_resource('lamp'), 'clone').returns(lamp);
      sinon.stub(jg._retrieve_resource('particles'), 'clone').returns(particles);

    });

    after(function(){
      jg._retrieve_resource('lamp').clone.restore();
      jg._retrieve_resource('particles').clone.restore();
    });

    it("loads jump gate gfx", function(){
      sinon.spy(jg, 'load_gfx');
      jg.init_gfx();
      sinon.assert.called(jg.load_gfx);
    });

    it("clones JumpGate mesh", function(){
      jg.init_gfx();
      sinon.assert.calledWith(jg._retrieve_async_resource,
                              'jump_gate.geometry', sinon.match.func);
      jg._retrieve_async_resource.omega_callback()(geo);
      assert(jg.mesh).isOfType(Omega.JumpGateMesh);
    });

    it("sets position tracker position", function(){
      jg.init_gfx();
      assert(jg.position_tracker().position.x).equals(100);
      assert(jg.position_tracker().position.y).equals(-100);
      assert(jg.position_tracker().position.z).equals(200);
    });

    it("sets mesh.omega_entity", function(){
      jg.init_gfx();
      jg._retrieve_async_resource.omega_callback()(geo);
      assert(jg.mesh.omega_entity).equals(jg);
    });

    it("adds mesh to position tracker", function(){
      jg.init_gfx();
      jg._retrieve_async_resource.omega_callback()(geo);
      assert(jg.position_tracker().getDescendants()).includes(jg.mesh.tmesh);
    });

    it("adds lamp to mesh", function(){
      jg.init_gfx();
      jg._retrieve_async_resource.omega_callback()(geo);
      assert(jg.mesh.tmesh.getDescendants()).
        includes(jg.lamp.olamp.component);
    });

    it("clones JumpGate lamp", function(){
      jg.init_gfx();
      assert(jg.lamp).equals(lamp);
    });

    it("sets lamp position", function(){
      var offset = Omega.JumpGateLamp.prototype.offset;
      jg.init_gfx();
      assert(jg.lamp.olamp.component.position.toArray()).
        isSameAs([offset[0],
                  offset[1],
                  offset[2]])
    });

    it("clones JumpGate particles", function(){
      jg.init_gfx();
      assert(jg.particles).equals(particles);
    });

    it("adds particles to position tracker", function(){
      jg.init_gfx();
      assert(jg.position_tracker().getDescendants()).includes(jg.particles.component());
    });

    it("creates a selection sphere for jg", function(){
      jg.init_gfx();
      assert(jg.selection).isOfType(Omega.JumpGateSelection);
    });

    it("sets selection sphere position", function(){
      jg.init_gfx();
      assert(jg.selection.tmesh.position.toArray()).
        isSameAs([0,0,0]);
    });

    it("creates local reference to jump gate triggering audio", function(){
      var audio = jg._retrieve_resource('trigger_audio');
      jg.init_gfx();
      assert(jg.trigger_audio).equals(audio);
    });

    /// it("sets selection sphere radius") NIY

    it("adds position tracker to jump gate scene components", function(){
      jg.init_gfx();
      assert(jg.components).isSameAs([jg.position_tracker()]);
    });

    it("updates gfx", function(){
      sinon.spy(jg, 'update_gfx');
      jg.init_gfx();
      sinon.assert.called(jg.update_gfx);
    });
  });

  describe("#update_gfx", function(){
    it("updates position tracker location using scene location", function(){
      jg.init_gfx();
      jg.update_gfx();

      var pos = jg.position_tracker().position;
      assert(pos.x).equals( 100);
      assert(pos.y).equals(-100);
      assert(pos.z).equals( 200);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      jg.init_gfx();
      sinon.spy(jg.lamp, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.lamp.run_effects);
    });

    it("runs particles effects", function(){
      jg.init_gfx();
      sinon.spy(jg.particles, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.particles.run_effects);
    });

    it("runs mesh effects", function(){
      jg.init_gfx();
      sinon.spy(jg.mesh, 'run_effects');
      jg.run_effects();
      sinon.assert.called(jg.mesh.run_effects);
    });
  });
});});
