/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfxInitializer", function(){
describe("Omega.JumpGateGfxInitializer", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.location.set(100, -100, 200);
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

    it("retrieves JumpGate geometry and creates mesh", function(){
      jg.init_gfx();
      sinon.assert.calledWith(jg._retrieve_async_resource,
                              'jump_gate.geometry', sinon.match.func);
      jg._retrieve_async_resource.omega_callback()(geo);
      assert(jg.mesh).isOfType(Omega.JumpGateMesh);
      assert(jg.mesh.tmesh.geometry).equals(geo);
      assert(jg.mesh.tmesh.material).equals(jg._retrieve_resource('mesh_material').material);
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
});});
