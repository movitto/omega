pavlov.specify("Omega.StationLamps", function(){
describe("Omega.StationLamps", function(){
  it("has a Omega.UI.CanavasLamp instance", function(){
    var type = 'manufacturing';
    var station_lamps = new Omega.StationLamps({config: Omega.Config, type: type});

    assert(station_lamps.olamps.length).
      equals(Omega.Config.resources.stations[type].lamps.length);

    for(var l = 0; l < station_lamps.length; l++){
      var lamp = station_lamps[l];
      assert(lamp).isOfType(Omega.UI.CanvasLamp);
    }
  });
});}); // Omega.StationLamps
