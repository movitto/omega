pavlov.specify("Omega.ShipLamps", function(){
describe("Omega.ShipLamps", function(){
  it("has a Omega.UI.CanavasLamp instance", function(){
    var type = 'corvette';
    var ship_lamps = new Omega.ShipLamps({type: type});

    assert(ship_lamps.olamps.length).
      equals(Omega.Config.resources.ships[type].lamps.length);

    for(var l = 0; l < ship_lamps.length; l++){
      var lamp = ship_lamps[l];
      assert(lamp).isOfType(Omega.UI.CanvasLamp);
    }
  });
});}); // Omega.ShipHighlightEffects
