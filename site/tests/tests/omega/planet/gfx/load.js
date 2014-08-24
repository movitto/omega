/// Test Mixin usage through Planet
pavlov.specify("Omega.PlanetGfxLoader", function(){
describe("Omega.PlanetGfxLoader", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        var planet = new Omega.Planet();
        sinon.stub(planet, 'gfx_loaded').returns(true)
        sinon.spy(planet, '_loaded_gfx');
        planet.load_gfx();
        sinon.assert.notCalled(planet._loaded_gfx);
      });
    });

    it("creates mesh for Planet", function(){
      var planet = Omega.Test.entities()['planet'];
      var mesh   = planet._retrieve_resource('mesh');
      assert(mesh).isOfType(Omega.PlanetMesh);
    });

    it("creates axis for Planet", function(){
      var planet = Omega.Test.entities()['planet'];
      var axis   = planet._retrieve_resource('axis');
      assert(axis).isOfType(Omega.PlanetAxis);
    });
  });
});});
