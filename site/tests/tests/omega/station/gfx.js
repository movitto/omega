// Test mixin usage through ship
pavlov.specify("Omega.StationGfx", function(){
describe("Omega.StationGfx", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = Omega.Station.gfx;
      });

      after(function(){
        Omega.Station.gfx = orig;
      });

      it("does nothing / just returns", function(){
        Omega.Station.gfx = {'manufacturing' : {lamps:null}};
        new Omega.Station({type:'manufacturing'}).load_gfx();
        assert(Omega.Station.gfx['manufacturing'].lamps).isNull();
      });
    });

    it("creates mesh for Station", function(){
      var station = Omega.Test.Canvas.Entities().station;
      assert(Omega.Station.gfx[station.type].mesh).isOfType(Omega.StationMesh);
      assert(Omega.Station.gfx[station.type].mesh.tmesh).isOfType(THREE.Mesh);
      assert(Omega.Station.gfx[station.type].mesh.tmesh.material).isOfType(Omega.StationMeshMaterial);
      assert(Omega.Station.gfx[station.type].mesh.tmesh.geometry).isOfType(THREE.Geometry);
        /// TODO assert material texture & geometry src path values
    });

    it("creates highlight effects for Station", function(){
      var station = Omega.Test.Canvas.Entities().station;
      assert(Omega.Station.gfx[station.type].highlight).isOfType(Omega.StationHighlightEffects);
      assert(Omega.Station.gfx[station.type].highlight.mesh.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.Station.gfx[station.type].highlight.mesh.geometry).isOfType(THREE.CylinderGeometry);
    });

    it("creates lamps for Station", function(){
      var station = Omega.Test.Canvas.Entities().station;
      assert(Omega.Station.gfx[station.type].lamps.olamps.length).
        equals(Omega.Config.resources.stations[station.type].lamps.length);
      for(var l = 0; l < Omega.Station.gfx[station.type].lamps.length; l++){
        var lamp = Omega.Station.gfx[station.type].lamps[l];
        assert(lamp).isOfType(Omega.UI.CanvasLamp);
      }
    });

    // it("creates progress bar for station construction"); // NIY
  });

  describe("#init_gfx", function(){
    var type = 'manufacturing';
    var station;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      station = new Omega.Station({type: type,
        location : new Omega.Location({x: 100, y: -100, z: 200})});
    });

    after(function(){
      if(Omega.Station.gfx){
        if(Omega.Station.gfx[type].mesh && Omega.Station.gfx[type].mesh.clone.restore) Omega.Station.gfx[type].mesh.clone.restore();
        if(Omega.Station.gfx[type].highlight && Omega.Station.gfx[type].highlight.clone.restore) Omega.Station.gfx[type].highlight.clone.restore();
        if(Omega.Station.gfx[type].lamps)
          for(var l = 0; l < Omega.Station.gfx[type].lamps.length; l++)
            if(Omega.Station.gfx[type].lamps[l].clone.restore)
              Omega.Station.gfx[type].lamps[l].clone.restore();
        if(Omega.Station.gfx[type].construction_bar && Omega.Station.gfx[type].construction_bar.clone.restore)
          Omega.Station.gfx[type].construction_bar.clone.restore();
      }
      if(Omega.Station.prototype.retrieve_resource.restore)
        Omega.Station.prototype.retrieve_resource.restore();
    });

    it("loads station gfx", function(){
      var station   = new Omega.Station({type: type});
      var load_gfx  = sinon.spy(station, 'load_gfx');
      station.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones template mesh", function(){
      var mesh = new Omega.StationMesh({mesh: new THREE.Mesh()});
      var cloned = new Omega.StationMesh({mesh: new THREE.Mesh()});

      var retrieve_resource = sinon.stub(Omega.Station.prototype, 'retrieve_resource');
      station.init_gfx();
      sinon.assert.calledWith(retrieve_resource, 'template_mesh_' + station.type, sinon.match.func);
      var retrieve_resource_cb = retrieve_resource.getCall(0).args[1];

      var clone = sinon.stub(mesh, 'clone').returns(cloned);
      retrieve_resource_cb(mesh);
      assert(station.mesh).equals(cloned);
    });

    it("sets mesh position", function(){
      station.init_gfx();
      assert(station.mesh.tmesh.position.x).equals(100);
      assert(station.mesh.tmesh.position.y).equals(-100);
      assert(station.mesh.tmesh.position.z).equals(200);
    });

    it("sets mesh omega_entity", function(){
      station.init_gfx();
      assert(station.mesh.omega_entity).equals(station);
    });

    it("adds mesh to components", function(){
      station.init_gfx();
      assert(station.components).includes(station.mesh.tmesh);
    });

    it("clones Station highlight effects", function(){
      var mesh = new Omega.StationHighlightEffects();
      sinon.stub(Omega.Station.gfx[type].highlight, 'clone').returns(mesh);
      station.init_gfx();
      assert(station.highlight).equals(mesh);
    });

    it("sets omega_entity on highlight effects", function(){
      station.init_gfx();
      assert(station.highlight.omega_entity).equals(station);
    });

    it("clones Station lamps", function(){
      var spies = [];
      var lamps = Omega.Station.gfx[type].lamps.olamps;
      for(var l = 0; l < lamps.length; l++)
        spies.push(sinon.spy(lamps[l], 'clone'));
      station.init_gfx();
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("clones station construction progress bar", function(){
      var bar = Omega.Station.gfx[type].construction_bar.clone();
      sinon.stub(Omega.Station.gfx[type].construction_bar, 'clone').returns(bar);
      station.init_gfx();
      assert(station.construction_bar).equals(bar);
    });

    it("sets scene components to station highlight effects, and lamps", function(){
      station.init_gfx();
      assert(station.components).includes(station.highlight.mesh);
      for(var l = 0; l < station.lamps.olamps.length; l++)
        assert(station.components).includes(station.lamps.olamps[l].component);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      var station = Omega.Gen.station({type : 'manufacturing'});
      station.init_gfx();

      var spies = [];
      for(var l = 0; l < station.lamps.olamps.length; l++)
        spies.push(sinon.spy(station.lamps.olamps[l], 'run_effects'))

      station.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });
  });

  describe("#cp_gfx", function(){
    var orig, station;
    before(function(){
      orig = {components        : 'components',
              shader_components : 'shader_components',
              mesh              : 'mesh',
              highlight         : 'highlight',
              lamps             : 'lamps',
              construction_bar  : 'construction_bar'}
      station = new Omega.Station();
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
      var station = new Omega.Station({type: 'manufacturing',
                      location : new Omega.Location({x:0,y:0,z:0})});
      station.init_gfx(Omega.Config);
      var update = sinon.spy(station.construction_bar, 'update');
      station.update_gfx();
      sinon.assert.called(update);
    });
  });

});});
