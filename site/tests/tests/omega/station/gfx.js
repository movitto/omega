// Test mixin usage through ship
pavlov.specify("Omega.StationGfx", function(){
describe("Omega.StationGfx", function(){
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
      var station = Omega.Test.Canvas.Entities()['station'];
      var highlight = station._retrieve_resource('highlight');
      assert(highlight).isOfType(Omega.StationHighlightEffects);
    });

    it("creates lamps for Station", function(){
      var station  = Omega.Test.Canvas.Entities()['station'];
      var lamps = station._retrieve_resource('lamps');
      assert(lamps).isOfType(Omega.StationLamps);
    });

    it("creates progress bar for station construction", function(){
      var station  = Omega.Test.Canvas.Entities()['station'];
      var bar = station._retrieve_resource('construction_bar');
      assert(bar).isOfType(Omega.StationConstructionBar);
    });

    it("creates station construction audio instance", function(){
      var station  = Omega.Test.Canvas.Entities()['station'];
      var audio = station._retrieve_resource('construction_audio');
      assert(audio).isOfType(Omega.StationConstructionAudioEffect);
    });
  });

  describe("#init_gfx", function(){
    var type = 'manufacturing';
    var geo, highlight, lamps, construction_bar;

    before(function(){
      geo              = new THREE.Geometry();
      highlight        = new Omega.StationHighlightEffects();
      lamps            = new Omega.StationLamps({type : type});
      construction_bar = new Omega.StationConstructionBar();
      sinon.stub(station, '_retrieve_async_resource');
      sinon.stub(station._retrieve_resource('highlight'),        'clone').returns(highlight);
      sinon.stub(station._retrieve_resource('lamps'),            'clone').returns(lamps);
      sinon.stub(station._retrieve_resource('construction_bar'), 'clone').returns(construction_bar);
    });

    after(function(){
      station._retrieve_resource('highlight').clone.restore();
      station._retrieve_resource('lamps').clone.restore();
      station._retrieve_resource('construction_bar').clone.restore();
    });

    it("loads station gfx", function(){
      sinon.spy(station, 'load_gfx');
      station.init_gfx();
      sinon.assert.called(station.load_gfx);
    });

    it("retrieves Station geometry and creates mesh", function(){
      var cloned_geo = new THREE.Geometry();
      sinon.stub(geo, 'clone').returns(cloned_geo);

      var mat = station._retrieve_resource('mesh_material').material;
      var cloned_mat = new THREE.MeshBasicMaterial();
      sinon.stub(mat, 'clone').returns(cloned_mat);

      station.init_gfx();
      sinon.assert.calledWith(station._retrieve_async_resource,
                              'station.'+type+'.mesh_geometry', sinon.match.func);

      station._retrieve_async_resource.omega_callback()(geo);
      assert(station.mesh).isOfType(Omega.StationMesh);
      assert(station.mesh.tmesh.geometry).equals(cloned_geo);
      assert(station.mesh.tmesh.material).equals(cloned_mat);
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

  describe("#update_gfx", function(){
    it("sets position tracker location from scene location", function(){
      var loc = new Omega.Location();
      loc.set(-123, 234, -321);
      sinon.stub(station, 'scene_location').returns(loc);

      station.update_gfx();
      var position = station.position_tracker().position;
      assert(position.x).equals(-123);
      assert(position.y).equals(234);
      assert(position.z).equals(-321);
    });

    describe("station is stopped", function(){
      before(function(){
        sinon.stub(station.location, 'is_stopped').returns(true);
      });

      it("removes orbit line", function(){
        sinon.stub(station, '_has_orbit_line').returns(true);
        sinon.stub(station, '_rm_orbit_line');
        station.update_gfx();
        sinon.assert.called(station._rm_orbit_line);
      });

      it("resets run movement method", function(){
        station.update_gfx();
        assert(station._run_movement_effects).equals(station._run_movement);
      });
    });

    describe("station is not stopped", function(){
      before(function(){
        sinon.stub(station.location, 'is_stopped').returns(false);
        sinon.stub(station, '_has_orbit_line').returns(false);
      });

      it("calculates orbit", function(){
        sinon.spy(station, '_calc_orbit');
        station.update_gfx();
        sinon.assert.called(station._calc_orbit);
      });

      it("calculates current orbit angle", function(){
        sinon.spy(station, '_current_orbit_angle');
        station.update_gfx();
        sinon.assert.called(station._current_orbit_angle);
      });

      it("Adds orbit line", function(){
        sinon.spy(station, '_add_orbit_line');
        station.update_gfx();
        sinon.assert.called(station._add_orbit_line);
      });

      it("sets movement method to orbit movement method", function(){
        station.init_gfx();
        station.update_gfx();
        assert(station._run_movement_effects).equals(station._run_orbit_movement);
      });
    });
  });

  describe("#update_construction_gfx", function(){
    it("updates station construction bar", function(){
      station.init_gfx();
      var update = sinon.spy(station.construction_bar, 'update');
      station.update_construction_gfx();
      sinon.assert.called(update);
    });
  });

  describe("#_run_movement", function(){
    it("does nothing / does not move station", function(){
      var coordinates = station.location.coordinates();
      station._run_movement();
      assert(station.location.coordinates()).isSameAs(coordinates);
    });
  });

  describe("#_run_orbit_movement", function(){
    it("updates station orbit angle", function(){
      station.last_moved = new Date(new Date() - 1000); // last moved 1s ago
      station.location.movement_strategy = {speed : 1.57};
      station._orbit_angle = 0;
      sinon.stub(station, 'update_gfx'); /// stub out update gfx
      sinon.stub(station, '_set_orbit_angle');
      station._run_orbit_movement();
      assert(station._orbit_angle).equals(1.57);
      sinon.assert.calledWith(station._set_orbit_angle, 1.57);
    });

    it("sets last moved", function(){
      sinon.stub(station, '_set_orbit_angle'); /// stub out set_orbit_angle
      station._run_orbit_movement();
      assert(station.last_moved).isNotNull();
    });

    it("updates station gfx", function(){
      sinon.stub(station, '_set_orbit_angle'); /// stub out set_orbit_angle
      sinon.stub(station, 'update_gfx');
      station._run_orbit_movement();
      sinon.assert.called(station.update_gfx);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      station.init_gfx();

      var spies = [];
      for(var l = 0; l < station.lamps.olamps.length; l++)
        spies.push(sinon.spy(station.lamps.olamps[l], 'run_effects'))

      station.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("runs movement effects", function(){
      sinon.stub(station, '_run_movement_effects');
      station.run_effects();
      sinon.assert.called(station._run_movement_effects);
    });
  });
});});
