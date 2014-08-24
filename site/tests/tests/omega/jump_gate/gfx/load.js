/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfxLoader", function(){
describe("Omega.JumpGateGfxLoader", function(){
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
      var jg  = Omega.Test.entities()['jump_gate'];
      var mat = jg._retrieve_resource('mesh_material');
      assert(mat).isOfType(Omega.JumpGateMeshMaterial);
    });

    it("creates lamp for JumpGate", function(){
      var jg   = Omega.Test.entities()['jump_gate'];
      var lamp = jg._retrieve_resource('lamp');
      assert(lamp).isOfType(Omega.JumpGateLamp);
    });

    it("creates particle system for JumpGate", function(){
      var jg = Omega.Test.entities()['jump_gate'];
      var particles = jg._retrieve_resource('particles');
      assert(particles).isOfType(Omega.JumpGateParticles);
    });

    it("creates selection material for JumpGate", function(){
      var jg  = Omega.Test.entities()['jump_gate'];
      var mat = jg._retrieve_resource('selection_material');
      assert(mat).isOfType(Omega.JumpGateSelectionMaterial);
    });

    it("creates audio effect for JumpGate triggering", function(){
      var jg    = Omega.Test.entities()['jump_gate'];
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
});});
