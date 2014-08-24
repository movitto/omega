// Test mixin usage through ship
pavlov.specify("Omega.StationGfxLoader", function(){
describe("Omega.StationGfxLoader", function(){
  var station;

  before(function(){
    station = Omega.Gen.station({type: 'manufacturing'});
    station.location = new Omega.Location({x: 100, y: -100, z: 200});
    station.location.movement_strategy = {json_class : 'Motel::MovementStrategies::Stopped'};
  });

  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      it("does nothing / just returns", function(){
        sinon.stub(station, 'gfx_loaded').returns(true);
        sinon.spy(station, '_loaded_gfx');
        station.load_gfx();
        sinon.assert.notCalled(station._loaded_gfx);
      });
    });

    it("loads Station mesh geometry", function(){
      var event_cb = function(){};
      var geometry = Omega.StationMesh.geometry_for(station.type);
      sinon.stub(station, 'gfx_loaded').returns(false);
      sinon.stub(station, '_load_async_resource');
      station.load_gfx(event_cb);

      var id = 'station.' + station.type + '.mesh_geometry';
      sinon.assert.calledWith(station._load_async_resource, id, geometry, event_cb);
    });

    it("creates highlight effects for Station", function(){
      var station = Omega.Test.entities()['station'];
      var highlight = station._retrieve_resource('highlight');
      assert(highlight).isOfType(Omega.StationHighlightEffects);
    });

    it("creates lamps for Station", function(){
      var station  = Omega.Test.entities()['station'];
      var lamps = station._retrieve_resource('lamps');
      assert(lamps).isOfType(Omega.StationLamps);
    });

    it("creates progress bar for station construction", function(){
      var station  = Omega.Test.entities()['station'];
      var bar = station._retrieve_resource('construction_bar');
      assert(bar).isOfType(Omega.StationConstructionBar);
    });

    it("creates station construction audio instance", function(){
      var station  = Omega.Test.entities()['station'];
      var audio = station._retrieve_resource('construction_audio');
      assert(audio).isOfType(Omega.StationConstructionAudioEffect);
    });
  });
});});
