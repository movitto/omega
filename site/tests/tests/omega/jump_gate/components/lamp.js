pavlov.specify("Omega.JumpGateLamp", function(){
describe("Omega.JumpGateLamp", function(){
  it("has a Omega.UI.CanavasLamp instance", function(){
    var gate_lamp = new Omega.JumpGateLamp();
    assert(gate_lamp.olamp).isOfType(Omega.UI.CanvasLamp);
  });
});});
