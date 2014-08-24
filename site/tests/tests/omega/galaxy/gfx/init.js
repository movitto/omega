pavlov.specify("Omega.GalaxyGfxInitializer", function(){
describe("Omega.GalaxyGfxInitializer", function(){
  describe("#init_gfx", function(){
    before(function(){
      /// preiinit using test page
      Omega.Test.entities();
    });

    it("loads galaxy gfx", function(){
      var galaxy    = new Omega.Galaxy();
      var load_gfx  = sinon.spy(galaxy, 'load_gfx');
      galaxy.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("references Galaxy density_waves", function(){
      var galaxy = new Omega.Galaxy();
      galaxy.init_gfx();
      var stars = galaxy._retrieve_resource('stars');
      var clouds = galaxy._retrieve_resource('clouds');
      assert(galaxy.stars).equals(stars);
      assert(galaxy.clouds).equals(clouds);
    });

    it("adds particle system to galaxy scene components", function(){
      var galaxy = new Omega.Galaxy();
      galaxy.init_gfx();
      var expected = [galaxy.clouds.particles, galaxy.stars.particles];
      assert(galaxy.components).isSameAs(expected);
    });
  });
});});
