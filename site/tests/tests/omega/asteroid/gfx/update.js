pavlov.specify("Omega.AsteroidGfxUpdater", function(){
describe("Omega.AsteroidGfxUpdater", function(){
  describe("#update_gfx", function(){
    it("updates position tracker location using scene location", function(){
      var ast = Omega.Gen.asteroid();
      ast.location.set(50, -42.2, 1);
      ast.update_gfx();

      var pos = ast.position_tracker().position;
      assert(pos.x).equals(50);
      assert(pos.y).equals(-42.2);
      assert(pos.z).equals(1);
    });
  });
});});
