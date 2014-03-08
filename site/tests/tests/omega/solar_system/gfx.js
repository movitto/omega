/// Test Mixin usage through SolarSystem
pavlov.specify("Omega.SolarSystemGfx", function(){
describe("Omega.SolarSystemGfx", function(){
  var system;

  before(function(){
    system = new Omega.SolarSystem();
    system.location = new Omega.Location({x: 50, y:60, z:-75});
  });

  describe("#load_gfx", function(){
    describe("graphics are loaded", function(){
      var orig_gfx;

      before(function(){
        orig_gfx = Omega.SolarSystem.gfx;
        Omega.SolarSystem.gfx = null;
        sinon.stub(system, 'gfx_loaded').returns(true);
      });

      after(function(){
        Omega.SolarSystem.gfx = orig_gfx;
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

    it("sets mesh position", function(){
      system.init_gfx(Omega.Config);
      assert(system.mesh.tmesh.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("clones SolarSystem plane", function(){
      var plane = new Omega.SolarSystemPlane({config: Omega.Config});
      sinon.stub(Omega.SolarSystem.gfx.plane, 'clone').returns(plane);
      system.init_gfx(Omega.Config);
      assert(system.plane).equals(plane);
    });

    it("sets plane position", function(){
      system.init_gfx(Omega.Config);
      assert(system.plane.tmesh.position.toArray()).isSameAs([50, 60, -75]);
    });

    it("creates text for solar system", function(){
      system.init_gfx(Omega.Config);
      assert(system.text).isOfType(Omega.SolarSystemText);
    });

    it("sets text position", function(){
      system.init_gfx(Omega.Config);
      assert(system.text.text.position.toArray()).isSameAs([50, 110, -75]);
    });
    
    it("adds plane, text, particles to solar system scene components", function(){
      system.init_gfx(Omega.Config);
      assert(system.components).isSameAs([system.plane.tmesh,
                                          system.text.text,
                                          system.interconns.particles.mesh]);
    });

    it("unqueues interconnections", function(){
      sinon.stub(system.interconns, 'unqueue');
      system.init_gfx(Omega.Config);
      sinon.assert.calledWith(system.interconns.unqueue);
    })
  });

  describe("#run_effects", function(){
    //it("updates interconnect particles") // NIY
  });
});});
