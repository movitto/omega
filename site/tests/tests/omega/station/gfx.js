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
      var orig_gfx;

      before(function(){
        orig_gfx = Omega.Station.gfx;
        Omega.Station.gfx = null;
        sinon.stub(station, 'gfx_loaded').returns(true);
      });

      after(function(){
        Omega.Station.gfx = orig_gfx;
      });

      it("does nothing / just returns", function(){
        station.load_gfx();
        assert(Omega.Station.gfx).isNull();
      });
    });

    it("creates mesh for Station", function(){
      assert(Omega.Station.gfx[station.type].mesh).isOfType(Omega.StationMesh);
    });

    it("creates highlight effects for Station", function(){
      assert(Omega.Station.gfx[station.type].highlight).
        isOfType(Omega.StationHighlightEffects);
    });

    it("creates lamps for Station", function(){
      assert(Omega.Station.gfx[station.type].lamps).isOfType(Omega.StationLamps);
    });

    it("creates progress bar for station construction", function(){
      assert(Omega.Station.gfx[station.type].construction_bar).
        isOfType(Omega.StationConstructionBar);
    });

    it("creates station construction audio instance", function(){
      assert(Omega.Station.gfx[station.type].construction_audio).
        isOfType(Omega.StationConstructionAudioEffect);
    });
  });

  describe("#init_gfx", function(){
    var type = 'manufacturing';

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();
    });

    after(function(){
      if(Omega.Station.gfx[type].mesh.clone.restore)
        Omega.Station.gfx[type].mesh.clone.restore();

      if(Omega.Station.gfx[type].highlight.clone.restore)
        Omega.Station.gfx[type].highlight.clone.restore();

      for(var l = 0; l < Omega.Station.gfx[type].lamps.length; l++)
        if(Omega.Station.gfx[type].lamps[l].clone.restore)
          Omega.Station.gfx[type].lamps[l].clone.restore();

      if(Omega.Station.gfx[type].construction_bar.clone.restore)
        Omega.Station.gfx[type].construction_bar.clone.restore();

      if(Omega.Station.prototype.retrieve_resource.restore)
        Omega.Station.prototype.retrieve_resource.restore();
    });

    it("loads station gfx", function(){
      var station   = Omega.Gen.station({type: type});
      var load_gfx  = sinon.spy(station, 'load_gfx');
      station.init_gfx(Omega.Config);
      sinon.assert.called(load_gfx);
    });

    it("clones template mesh", function(){
      var mesh   = new Omega.StationMesh({mesh: new THREE.Mesh()});
      var cloned = new Omega.StationMesh({mesh: new THREE.Mesh()});

      sinon.stub(Omega.Station.prototype, 'retrieve_resource');
      station.init_gfx(Omega.Config);
      sinon.assert.calledWith(Omega.Station.prototype.retrieve_resource,
                              'template_mesh_' + station.type,
                              sinon.match.func);
      var retrieve_resource_cb =
        Omega.Station.prototype.retrieve_resource.getCall(0).args[1];

      var clone = sinon.stub(mesh, 'clone').returns(cloned);
      retrieve_resource_cb(mesh);
      assert(station.mesh).equals(cloned);
    });

    it("sets position tracker position", function(){
      station.init_gfx(Omega.Config);
      assert(station.position_tracker().position.x).equals(100);
      assert(station.position_tracker().position.y).equals(-100);
      assert(station.position_tracker().position.z).equals(200);
    });

    it("sets mesh omega_entity", function(){
      station.init_gfx(Omega.Config);
      assert(station.mesh.omega_entity).equals(station);
    });

    it("adds position tracker to components", function(){
      station.init_gfx(Omega.Config);
      assert(station.components).includes(station.position_tracker());
    });

    it("clones Station highlight effects", function(){
      var mesh = new Omega.StationHighlightEffects();
      sinon.stub(Omega.Station.gfx[type].highlight, 'clone').returns(mesh);
      station.init_gfx(Omega.Config);
      assert(station.highlight).equals(mesh);
    });

    it("sets omega_entity on highlight effects", function(){
      station.init_gfx(Omega.Config);
      assert(station.highlight.omega_entity).equals(station);
    });

    it("clones Station lamps", function(){
      var spies = [];
      var lamps = Omega.Station.gfx[type].lamps.olamps;
      for(var l = 0; l < lamps.length; l++)
        spies.push(sinon.spy(lamps[l], 'clone'));
      station.init_gfx(Omega.Config);
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("clones station construction progress bar", function(){
      var bar = Omega.Station.gfx[type].construction_bar.clone();
      sinon.stub(Omega.Station.gfx[type].construction_bar, 'clone').returns(bar);
      station.init_gfx(Omega.Config);
      assert(station.construction_bar).equals(bar);
    });

    it("adds mesh to position tracker", function(){
      station.init_gfx(Omega.Config);
      var descendents = station.position_tracker().getDescendants();
      assert(descendents).includes(station.mesh.tmesh);
    });

    describe("station.include_highlight is false", function(){
      it("does not add highlight to position tracker", function(){
        station.include_highlight = false;
        station.init_gfx(Omega.Config);
        var descendents = station.position_tracker().getDescendants();
        assert(descendents).doesNotInclude(station.highlight_mesh);
      });
    });

    describe("station.include_highlight is true", function(){
      it("adds highlight to position tracker", function(){
        station.include_highlight = true;
        station.init_gfx(Omega.Config);
        var descendents = station.position_tracker().getDescendants();
        assert(descendents).includes(station.highlight.mesh);
      });
    });

    it("adds lamps to mesh", function(){
      station.init_gfx(Omega.Config);
      var descendents = station.mesh.tmesh.getDescendants();
      for(var l = 0; l < station.lamps.olamps.length; l++)
        assert(descendents).includes(station.lamps.olamps[l].component);
    });

    it("creates local reference to station construction audio", function(){
      station.init_gfx(Omega.Config);
      assert(station.construction_audio).
        equals(Omega.Station.gfx[station.type].construction_audio);
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
        station.init_gfx(Omega.Config);
        station.update_gfx();
        assert(station._run_movement_effects).equals(station._run_orbit_movement);
      });
    });
  });

  describe("#update_construction_gfx", function(){
    it("updates station construction bar", function(){
      station.init_gfx(Omega.Config);
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
      station.init_gfx(Omega.Config);

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
