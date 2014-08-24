// Test mixin usage through ship
pavlov.specify("Omega.StationGfxInitializer", function(){
describe("Omega.StationGfxInitializer", function(){
  var station;

  before(function(){
    station = Omega.Gen.station({type: 'manufacturing'});
    station.location = new Omega.Location({x: 100, y: -100, z: 200});
    station.location.movement_strategy = {json_class : 'Motel::MovementStrategies::Stopped'};
  });

  describe("#init_gfx", function(){
    var type = 'manufacturing';
    var geo, highlight, lamps, construction_bar, material;

    before(function(){
      geo              = new THREE.Geometry();
      highlight        = new Omega.StationHighlightEffects();
      lamps            = new Omega.StationLamps({type : type});
      construction_bar = new Omega.StationConstructionBar();
      material         = new THREE.MeshBasicMaterial();
      sinon.stub(station, '_retrieve_async_resource');
      sinon.stub(station._retrieve_resource('highlight'),        'clone').returns(highlight);
      sinon.stub(station._retrieve_resource('lamps'),            'clone').returns(lamps);
      sinon.stub(station._retrieve_resource('construction_bar'), 'clone').returns(construction_bar);
      sinon.stub(station._retrieve_resource('mesh_material').material, 'clone').returns(material);
    });

    after(function(){
      station._retrieve_resource('highlight').clone.restore();
      station._retrieve_resource('lamps').clone.restore();
      station._retrieve_resource('construction_bar').clone.restore();
      station._retrieve_resource('mesh_material').material.clone.restore();
    });

    it("loads station gfx", function(){
      sinon.spy(station, 'load_gfx');
      station.init_gfx();
      sinon.assert.called(station.load_gfx);
    });

    it("retrieves Station geometry and creates mesh", function(){
      var cloned_geo = new THREE.Geometry();
      sinon.stub(geo, 'clone').returns(cloned_geo);

      station.init_gfx();
      sinon.assert.calledWith(station._retrieve_async_resource,
                              'station.'+type+'.mesh_geometry', sinon.match.func);

      station._retrieve_async_resource.omega_callback()(geo);
      assert(station.mesh).isOfType(Omega.StationMesh);
      assert(station.mesh.tmesh.geometry).equals(cloned_geo);
      assert(station.mesh.tmesh.material).equals(material);
    });

    it("sets position tracker position", function(){
      station.init_gfx();
      assert(station.position_tracker().position.x).equals(100);
      assert(station.position_tracker().position.y).equals(-100);
      assert(station.position_tracker().position.z).equals(200);
    });

    it("sets mesh omega_entity", function(){
      station.init_gfx();
      station._retrieve_async_resource.omega_callback()(geo);
      assert(station.mesh.omega_entity).equals(station);
    });

    it("adds position tracker to components", function(){
      station.init_gfx();
      assert(station.components).includes(station.position_tracker());
    });

    it("clones Station highlight effects", function(){
      station.init_gfx();
      assert(station.highlight).equals(highlight);
    });

    it("sets omega_entity on highlight effects", function(){
      station.init_gfx();
      assert(station.highlight.omega_entity).equals(station);
    });

    it("clones Station lamps", function(){
      station.init_gfx();
      assert(station.lamps).equals(lamps);
      assert(station.lamps.omega_entity).equals(station);
    });

    it("clones station construction progress bar", function(){
      station.init_gfx();
      assert(station.construction_bar).equals(construction_bar);
    });

    it("adds mesh to position tracker", function(){
      station.init_gfx();
      station._retrieve_async_resource.omega_callback()(geo);
      assert(station.position_tracker().children).includes(station.mesh.tmesh);
    });

    describe("station.include_highlight is false", function(){
      it("does not add highlight to position tracker", function(){
        station.include_highlight = false;
        station.init_gfx();
        assert(station.position_tracker().children).doesNotInclude(station.highlight_mesh);
      });
    });

    describe("station.include_highlight is true", function(){
      it("adds highlight to position tracker", function(){
        station.include_highlight = true;
        station.init_gfx();
        assert(station.position_tracker().children).includes(station.highlight.mesh);
      });
    });

    it("adds lamps to mesh", function(){
      station.init_gfx();
      station._retrieve_async_resource.omega_callback()(geo);
      var children = station.mesh.tmesh.children;
      for(var l = 0; l < station.lamps.olamps.length; l++)
        assert(children).includes(station.lamps.olamps[l].component);
    });

    it("creates local reference to station construction audio", function(){
      station.init_gfx();
      assert(station.construction_audio).equals(station._retrieve_resource('construction_audio'));
    });
  });
});});
