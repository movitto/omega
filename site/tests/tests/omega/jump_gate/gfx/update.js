/// Test Mixin usage through JumpGate
pavlov.specify("Omega.JumpGateGfxUpdater", function(){
describe("Omega.JumpGateGfxUpdater", function(){
  var jg;

  before(function(){
    jg = Omega.Gen.jump_gate();
    jg.location.set(100, -100, 200);
  });

  describe("#update_gfx", function(){
    it("updates position tracker location using scene location", function(){
      jg.init_gfx();
      jg.update_gfx();

      var pos = jg.position_tracker().position;
      assert(pos.x).equals( 100);
      assert(pos.y).equals(-100);
      assert(pos.z).equals( 200);
    });
  });
});});
