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

    // it("creates progress bar for station construction"); // NIY
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
      var station   = new Omega.Station({type: type});
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

    it("sets mesh position", function(){
      station.init_gfx(Omega.Config);
      assert(station.mesh.tmesh.position.x).equals(100);
      assert(station.mesh.tmesh.position.y).equals(-100);
      assert(station.mesh.tmesh.position.z).equals(200);
    });

    it("sets mesh omega_entity", function(){
      station.init_gfx(Omega.Config);
      assert(station.mesh.omega_entity).equals(station);
    });

    it("adds mesh to components", function(){
      station.init_gfx(Omega.Config);
      assert(station.components).includes(station.mesh.tmesh);
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

    it("sets scene components to station highlight effects, and lamps", function(){
      station.init_gfx(Omega.Config);
      assert(station.components).includes(station.highlight.mesh);
      for(var l = 0; l < station.lamps.olamps.length; l++)
        assert(station.components).includes(station.lamps.olamps[l].component);
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
  });

  describe("#cp_gfx", function(){
    var orig;
    before(function(){
      orig = {components        : 'components',
              shader_components : 'shader_components',
              mesh              : 'mesh',
              highlight         : 'highlight',
              lamps             : 'lamps',
              construction_bar  : 'construction_bar'}
    });

    it("copies station scene components", function(){
      station.cp_gfx(orig);
      assert(station.components).equals(orig.components);
    });

    it("copies station shader scene components", function(){
      station.cp_gfx(orig);
      assert(station.shader_components).equals(orig.shader_components);
    });

    it("copies station mesh", function(){
      station.cp_gfx(orig);
      assert(station.mesh).equals(orig.mesh);
    });

    it("copies station highlight", function(){
      station.cp_gfx(orig);
      assert(station.highlight).equals(orig.highlight);
    });

    it("copies station lamps", function(){
      station.cp_gfx(orig);
      assert(station.lamps).equals(orig.lamps);
    });

    it("copies station construction bar", function(){
      station.cp_gfx(orig);
      assert(station.construction_bar).equals(orig.construction_bar);
    });
  });

  describe("#update_gfx", function(){
    it("updates station construction bar", function(){
      station.init_gfx(Omega.Config);
      var update = sinon.spy(station.construction_bar, 'update');
      station.update_gfx();
      sinon.assert.called(update);
    });
  });

});});
