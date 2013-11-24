pavlov.specify("Omega.Station", function(){
describe("Omega.Station", function(){
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

    it("creates mesh for Station", async(function(){
      var station = Omega.Test.Canvas.Entities().station;
      station.retrieve_resource('mesh', function(){
        assert(Omega.Station.gfx[station.type].mesh).isOfType(THREE.Mesh);
        assert(Omega.Station.gfx[station.type].mesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.Station.gfx[station.type].mesh.geometry).isOfType(THREE.Geometry);
        start();
        /// TODO assert material texture & geometry src path values
      });
    }));

    it("creates highlight effects for Station", function(){
      var station = Omega.Test.Canvas.Entities().station;
      assert(Omega.Station.gfx[station.type].highlight).isOfType(THREE.Mesh);
      assert(Omega.Station.gfx[station.type].highlight.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.Station.gfx[station.type].highlight.geometry).isOfType(THREE.CylinderGeometry);
    });

    it("creates lamps for Station", function(){
      var station = Omega.Test.Canvas.Entities().station;
      assert(Omega.Station.gfx[station.type].lamps.length).equals(Omega.Config.resources.stations[station.type].lamps.length);
      for(var l = 0; l < Omega.Station.gfx[station.type].lamps.length; l++){
        var lamp = Omega.Station.gfx[station.type].lamps[l];
        assert(lamp).isOfType(THREE.Mesh);
        assert(lamp.material).isOfType(THREE.MeshBasicMaterial);
        assert(lamp.geometry).isOfType(THREE.SphereGeometry);
      }
    });
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
      }
    });

    it("loads station gfx", function(){
      var station   = new Omega.Station({type: type});
      var load_gfx  = sinon.spy(station, 'load_gfx');
      station.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Station mesh", async(function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.Station.prototype.
        retrieve_resource('manufacturing', 'template_mesh', function(){
          sinon.stub(Omega.Station.gfx[type].mesh, 'clone').returns(mesh);
        });

      station.init_gfx();
      station.retrieve_resource('mesh', function(){
        assert(station.mesh).equals(mesh);
        start();
      });
    }));

    it("sets mesh position", async(function(){
      station.init_gfx();
      station.retrieve_resource('mesh', function(){
        assert(station.mesh.position.x).equals(100);
        assert(station.mesh.position.y).equals(-100);
        assert(station.mesh.position.z).equals(200);
        start();
      });
    }));

    it("sets mesh omega_entity", async(function(){
      station.init_gfx();
      station.retrieve_resource('mesh', function(){
        assert(station.mesh.omega_entity).equals(station);
        start();
      });
    }));

    it("clones Station highlight effects", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Station.gfx[type].highlight, 'clone').returns(mesh);
      station.init_gfx();
      assert(station.highlight).equals(mesh);
    });

    it("clones Station lamps", function(){
      var spies = [];
      for(var l = 0; l < Omega.Station.gfx[type].lamps.length; l++)
        spies.push(sinon.spy(Omega.Station.gfx[type].lamps[l], 'clone'));
      station.init_gfx();
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("sets scene components to station mesh, highlight effects, and lamps", function(){
      station.init_gfx();
      var expected = [station.mesh, station.highlight].concat(station.lamps);
      assert(station.components).isSameAs(expected);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      var station = new Omega.Station({type : 'manufacturing'});
      station.init_gfx();

      var spies = [];
      for(var l = 0; l < station.lamps.length; l++)
        spies.push(sinon.spy(station.lamps[l], 'run_effects'))

      station.run_effects();

      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });
  });

  describe("#owned_by", function(){
    var node, retrieval_cb, invoke_spy;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      invoke_spy = sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Station.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Station', 'owned_by', 'user1');
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Station.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new station instances", function(){
        Omega.Station.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id: 'st1'},{id: 'st2'}]});
        var stations = retrieval_cb.getCall(0).args[0];
        assert(stations.length).equals(2);
        assert(stations[0]).isOfType(Omega.Station);
        assert(stations[0].id).equals('st1');
        assert(stations[1]).isOfType(Omega.Station);
        assert(stations[1].id).equals('st2');
      });
    });
  });
});}); // Omega.Galaxy
