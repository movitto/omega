/// Test Mixin usage through SolarSystem
pavlov.specify("Omega.SolarSystemGfxLoader", function(){
describe("Omega.SolarSystemGfxLoader", function(){
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
});});
