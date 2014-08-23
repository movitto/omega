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
      it("does nothing / just returns", function(){
        sinon.stub(system, 'gfx_loaded').returns(true);
        sinon.spy(system, '_loaded_gfx');
        system.load_gfx();
        sinon.assert.notCalled(system._loaded_gfx);
      });
    });

    it("creates mesh for solar system", function(){
      var system = Omega.Test.entities()['solar_system'];
      var mesh   = system._retrieve_resource('mesh');
      assert(mesh).isOfType(Omega.SolarSystemMesh);
    });

    it("creates plane for solar system", function(){
      var system = Omega.Test.entities()['solar_system'];
      var plane  = system._retrieve_resource('plane');
      assert(plane).isOfType(Omega.SolarSystemPlane);
    });

    it("creates audio effects for solar system", function(){
      var system = Omega.Test.entities()['solar_system'];
      var hover  = system._retrieve_resource('hover_audio');
      var click  = system._retrieve_resource('click_audio');
      assert(hover).isOfType(Omega.SolarSystemHoverAudioEffect);
      assert(click).isOfType(Omega.SolarSystemClickAudioEffect);
    });

    it("creates particles for solar system", function(){
      var system = Omega.Test.entities()['solar_system'];
      var particles = system._retrieve_resource('particles');
      assert(particles).isOfType(Omega.SolarSystemParticles);
    });

    it("invokes _loaded_gfx", function(){
      sinon.stub(system, 'gfx_loaded').returns(false);
      sinon.stub(system, '_loaded_gfx');
      system.load_gfx();
      sinon.assert.called(system._loaded_gfx);
    });
  });

  describe("#init_gfx", function(){
    var mesh, plane, particles;

    before(function(){
      mesh = new Omega.SolarSystemMesh();
      plane = new Omega.SolarSystemPlane({});
      particles = new Omega.SolarSystemParticles({});

      sinon.stub(system._retrieve_resource('mesh'),      'clone').returns(mesh);
      sinon.stub(system._retrieve_resource('plane'),     'clone').returns(plane);
      sinon.stub(system._retrieve_resource('particles'), 'clone').returns(particles);
    });

    after(function(){
      system._retrieve_resource('mesh').clone.restore();
      system._retrieve_resource('plane').clone.restore();
      system._retrieve_resource('particles').clone.restore();
    });

    it("loads system gfx", function(){
      sinon.spy(system, 'load_gfx');
      system.init_gfx();
      sinon.assert.called(system.load_gfx);
    });

    it("clones SolarSystem mesh", function(){
      system.init_gfx();
      assert(system.mesh).equals(mesh);
    });
    
    it("sets omege_entity on mesh", function(){
      system.init_gfx();
      assert(system.mesh.omega_entity).equals(system);
    });

    it("sets position tracker position", function(){
      system.init_gfx();
      assert(system.position_tracker().position.toArray()).isSameAs([50, 60, -75]);
    });

    it("clones SolarSystem plane", function(){
      system.init_gfx();
      assert(system.plane).equals(plane);
    });

    it("adds plane to position tracker", function(){
      system.init_gfx();
      assert(system.position_tracker().children).includes(system.plane.tmesh);
    });

    it("creates text for solar system", function(){
      system.init_gfx();
      assert(system.text).isOfType(Omega.SolarSystemText);
    });

    it("adds text to position tracker", function(){
      system.init_gfx();
      assert(system.position_tracker().children).includes(system.text.text);
    });

    it("creates local reference to solar system audio", function(){
      system.init_gfx();
      assert(system.hover_audio).equals(system._retrieve_resource('hover_audio'));
      assert(system.click_audio).equals(system._retrieve_resource('click_audio'));
    });

    it("clones SolarSystem particles", function(){
      system.init_gfx();
      assert(system.particles).equals(particles);
    });
    
    it("adds position tracker, particles to solar system scene components", function(){
      system.init_gfx();
      var tracker = system.position_tracker();
      assert(system.components).isSameAs([tracker]);
      assert(tracker.children).includes(system.plane.tmesh);
      assert(tracker.children).includes(system.text.text);
      assert(tracker.children).includes(system.particles.component());
      assert(tracker.children).includes(system.interconns.component());
    });

    it("unqueues interconnections", function(){
      sinon.stub(system.interconns, 'unqueue');
      system.init_gfx();
      sinon.assert.calledWith(system.interconns.unqueue);
    })
  });

  describe("#update_gfx", function(){
    it("sets position tracker position", function(){
      system.init_gfx();
      system.location.set(100, -200, 300);
      system.update_gfx();
      assert(system.position_tracker().position.x).equals(100);
      assert(system.position_tracker().position.y).equals(-200);
      assert(system.position_tracker().position.z).equals(300);
    });
  });

  describe("#run_effects", function(){
    it("runs interconnect effects", function(){
      system.init_gfx();
      sinon.stub(system.interconns, 'run_effects');
      system.run_effects();
      sinon.assert.calledWith(system.interconns.run_effects);
    });

    it("runs particles effects", function(){
      system.init_gfx();
      sinon.stub(system.particles, 'run_effects');
      system.run_effects();
      sinon.assert.calledWith(system.particles.run_effects);
    });
  });
});});
