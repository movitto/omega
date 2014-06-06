/// Test Mixin usage through SolarSystem
pavlov.specify("Omega.SolarSystemGfx", function(){
describe("Omega.SolarSystemGfx", function(){
  var system;

  before(function(){
    system = new Omega.SolarSystem();
    system.location = new Omega.Location({x: 50, y:60, z:-75});
  });

  describe("#load_gfx", function(){
    var orig_gfx;

    before(function(){
      orig_gfx = Omega.SolarSystem.gfx;
    });

    after(function(){
      Omega.SolarSystem.gfx = orig_gfx;
    });

    describe("graphics are loaded", function(){
      before(function(){
        Omega.SolarSystem.gfx = null;
        sinon.stub(system, 'gfx_loaded').returns(true);
      });

      it("does nothing / just returns", function(){
        system.load_gfx(Omega.Config);
        assert(Omega.SolarSystem.gfx).isNull();
      });
    });

    it("creates mesh for solar system", function(){
      assert(Omega.SolarSystem.gfx.mesh).isOfType(Omega.SolarSystemMesh);
    });

    it("creates plane for solar system", function(){
      assert(Omega.SolarSystem.gfx.plane).isOfType(Omega.SolarSystemPlane);
    });

    it("creates audio effects for solar system", function(){
      assert(Omega.SolarSystem.gfx.audio_effects).
          isOfType(Omega.SolarSystemAudioEffects);
    });

    it("invokes _loaded_gfx", function(){
      sinon.stub(system, 'gfx_loaded').returns(false);
      sinon.stub(system, '_loaded_gfx');
      system.load_gfx(Omega.Config);
      sinon.assert.called(system._loaded_gfx);
    });
  });

  describe("#init_gfx", function(){
    after(function(){
      if(Omega.SolarSystem.gfx.mesh.clone.restore)
        Omega.SolarSystem.gfx.mesh.clone.restore();

      if(Omega.SolarSystem.gfx.plane.clone.restore)
        Omega.SolarSystem.gfx.plane.clone.restore();
    });

    it("loads system gfx", function(){
      sinon.spy(system, 'load_gfx');
      system.init_gfx(Omega.Config);
      sinon.assert.called(system.load_gfx);
    });

    it("clones SolarSystem mesh", function(){
      var mesh = new Omega.SolarSystemMesh();
      sinon.stub(Omega.SolarSystem.gfx.mesh, 'clone').returns(mesh);
      system.init_gfx(Omega.Config);
      assert(system.mesh).equals(mesh);
    });
    
    it("sets omege_entity on mesh", function(){
      system.init_gfx(Omega.Config);
      assert(system.mesh.omega_entity).equals(system);
    });

    it("sets position tracker position", function(){
      system.init_gfx(Omega.Config);
      assert(system.position_tracker().position.toArray()).isSameAs([50, 60, -75]);
    });

    it("clones SolarSystem plane", function(){
      var plane = new Omega.SolarSystemPlane({config: Omega.Config});
      sinon.stub(Omega.SolarSystem.gfx.plane, 'clone').returns(plane);
      system.init_gfx(Omega.Config);
      assert(system.plane).equals(plane);
    });

    it("adds plane to position tracker", function(){
      system.init_gfx(Omega.Config);
      assert(system.position_tracker().children).includes(system.plane.tmesh);
    });

    it("creates text for solar system", function(){
      system.init_gfx(Omega.Config);
      assert(system.text).isOfType(Omega.SolarSystemText);
    });

    it("adds text to position tracker", function(){
      system.init_gfx(Omega.Config);
      assert(system.position_tracker().children).includes(system.text.text);
    });

    it("creates local reference to solar system audio", function(){
      system.init_gfx(Omega.Config);
      assert(system.audio_effects).equals(Omega.SolarSystem.gfx.audio_effects);
    });
    
    it("adds position tracker, particles to solar system scene components", function(){
      system.init_gfx(Omega.Config);
      assert(system.components).isSameAs([system.position_tracker(),
                                          system.interconns.particles.mesh,
                                          system.particles.particles.mesh]);
    });

    it("unqueues interconnections", function(){
      sinon.stub(system.interconns, 'unqueue');
      system.init_gfx(Omega.Config);
      sinon.assert.calledWith(system.interconns.unqueue);
    })
  });

  describe("#update_gfx", function(){
    it("sets position tracker position", function(){
      system.init_gfx(Omega.Config);
      system.location.set(100, -200, 300);
      system.update_gfx();
      assert(system.position_tracker().position.x).equals(100);
      assert(system.position_tracker().position.y).equals(-200);
      assert(system.position_tracker().position.z).equals(300);
    });

    it("updates particles", function(){
      system.init_gfx(Omega.Config);
      sinon.stub(system.particles, 'update');
      system.update_gfx();
      sinon.assert.called(system.particles.update);
    });

    it("updates interconns", function(){
      system.init_gfx(Omega.Config);
      sinon.stub(system.interconns, 'update');
      system.update_gfx();
      sinon.assert.called(system.interconns.update);
    });
  });

  describe("#run_effects", function(){
    it("runs interconnect effects", function(){
      system.init_gfx(Omega.Config);
      sinon.stub(system.interconns, 'run_effects');
      system.run_effects();
      sinon.assert.calledWith(system.interconns.run_effects);
    });

    it("runs particles effects", function(){
      system.init_gfx(Omega.Config);
      sinon.stub(system.particles, 'run_effects');
      system.run_effects();
      sinon.assert.calledWith(system.particles.run_effects);
    });
  });
});});
