pavlov.specify("Omega.GalaxyGfxLoader", function(){
describe("Omega.GalaxyGfxLoader", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        var galaxy = new Omega.Galaxy();
        sinon.stub(galaxy, 'gfx_loaded').returns(true);
        sinon.spy(galaxy, '_loaded_gfx');
        galaxy.load_gfx();
        sinon.assert.notCalled(galaxy._loaded_gfx);
      });
    });

    it("creates stars for galaxy", function(){
      var galaxy = Omega.Test.entities()['galaxy'];
      var stars  = galaxy._retrieve_resource('stars');
      assert(stars).isOfType(Omega.GalaxyDensityWave);
      assert(stars.type).equals('stars');
    });

    it("creates clouds for galaxy", function(){
      var galaxy = Omega.Test.entities()['galaxy'];
      var clouds = galaxy._retrieve_resource('clouds');
      assert(clouds).isOfType(Omega.GalaxyDensityWave);
      assert(clouds.type).equals('clouds');
    });
  });
});});
