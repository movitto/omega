pavlov.specify("Omega.Ship", function(){
describe("Omega.Ship", function(){
  describe("#load_gfx", function(){
    describe("graphics are initialized", function(){
      var orig;

      before(function(){
        orig = Omega.Ship.gfx;
      });

      after(function(){
        Omega.Ship.gfx = orig;
      });

      it("does nothing / just returns", function(){
        Omega.Ship.gfx = {'corvette' : {lamps:null}};
        new Omega.Ship({type:'corvette'}).load_gfx();
        assert(Omega.Ship.gfx['corvette'].lamps).isNull();
      });
    });

    it("creates mesh for Ship", async(function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      ship.retrieve_resource('mesh', function(){
        assert(Omega.Ship.gfx[ship.type].mesh).isOfType(THREE.Mesh);
        assert(Omega.Ship.gfx[ship.type].mesh.material).isOfType(THREE.MeshLambertMaterial);
        assert(Omega.Ship.gfx[ship.type].mesh.geometry).isOfType(THREE.Geometry);
        start();
        /// TODO assert material texture & geometry src path values
      });
    }));

    it("creates highlight effects for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].highlight).isOfType(THREE.Mesh);
      assert(Omega.Ship.gfx[ship.type].highlight.material).isOfType(THREE.MeshBasicMaterial);
      assert(Omega.Ship.gfx[ship.type].highlight.geometry).isOfType(THREE.CylinderGeometry);
    });

    it("creates lamps for Ship", function(){
      var ship = Omega.Test.Canvas.Entities().ship;
      assert(Omega.Ship.gfx[ship.type].lamps.length).equals(Omega.Config.resources.ships[ship.type].lamps.length);
      for(var l = 0; l < Omega.Ship.gfx[ship.type].lamps.length; l++){
        var lamp = Omega.Ship.gfx[ship.type].lamps[l];
        assert(lamp).isOfType(THREE.Mesh);
        assert(lamp.material).isOfType(THREE.MeshBasicMaterial);
        assert(lamp.geometry).isOfType(THREE.SphereGeometry);
      }
    });
  });

  describe("#init_gfx", function(){
    var type = 'corvette';
    var ship;

    before(function(){
      /// preiinit using test page
      Omega.Test.Canvas.Entities();

      ship = new Omega.Ship({type: type,
        location : new Omega.Location({x: 100, y: -100, z: 200})});
    });

    after(function(){
      if(Omega.Ship.gfx){
        if(Omega.Ship.gfx[type].mesh && Omega.Ship.gfx[type].mesh.clone.restore) Omega.Ship.gfx[type].mesh.clone.restore();
        if(Omega.Ship.gfx[type].highlight && Omega.Ship.gfx[type].highlight.clone.restore) Omega.Ship.gfx[type].highlight.clone.restore();
        if(Omega.Ship.gfx[type].lamps)
          for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
            if(Omega.Ship.gfx[type].lamps[l].clone.restore)
              Omega.Ship.gfx[type].lamps[l].clone.restore();
      }
    });

    it("loads ship gfx", function(){
      var ship   = new Omega.Ship({type: type});
      var load_gfx  = sinon.spy(ship, 'load_gfx');
      ship.init_gfx();
      sinon.assert.called(load_gfx);
    });

    it("clones Ship mesh", async(function(){
      var mesh = new THREE.Mesh();
      /// need to wait till template mesh is loaded b4 wiring up stub
      Omega.Ship.prototype.
        retrieve_resource('corvette', 'template_mesh', function(){
          sinon.stub(Omega.Ship.gfx[type].mesh, 'clone').returns(mesh);
        });

      ship.init_gfx();
      ship.retrieve_resource('mesh', function(){
        assert(ship.mesh).equals(mesh);
        start();
      });
    }));

    it("sets mesh position", async(function(){
      ship.init_gfx();
      ship.retrieve_resource('mesh', function(){
        assert(ship.mesh.position.x).equals(100);
        assert(ship.mesh.position.y).equals(-100);
        assert(ship.mesh.position.z).equals(200);
        start();
      });
    }));

    it("sets mesh omega_entity", async(function(){
      ship.init_gfx();
      ship.retrieve_resource('mesh', function(){
        assert(ship.mesh.omega_entity).equals(ship);
        start();
      });
    }));

    it("clones Ship highlight effects", function(){
      var mesh = new THREE.Mesh();
      sinon.stub(Omega.Ship.gfx[type].highlight, 'clone').returns(mesh);
      ship.init_gfx();
      assert(ship.highlight).equals(mesh);
    });

    it("clones Ship lamps", function(){
      var spies = [];
      for(var l = 0; l < Omega.Ship.gfx[type].lamps.length; l++)
        spies.push(sinon.spy(Omega.Ship.gfx[type].lamps[l], 'clone'));
      ship.init_gfx();
      for(var s = 0; s < spies.length; s++)
        sinon.assert.called(spies[s]);
    });

    it("sets scene components to ship mesh, highlight effects, and lamps", function(){
      ship.init_gfx();
      var expected = [ship.mesh, ship.highlight].concat(ship.lamps);
      assert(ship.components).isSameAs(expected);
    });
  });

  describe("#run_effects", function(){
    it("runs lamp effects", function(){
      var ship = new Omega.Ship({type : 'corvette'});
      ship.init_gfx();

      var spies = [];
      for(var l = 0; l < ship.lamps.length; l++)
        spies.push(sinon.spy(ship.lamps[l], 'run_effects'))

      ship.run_effects();

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
      Omega.Ship.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(invoke_spy, 'manufactured::get_entities',
        'of_type', 'Manufactured::Ship', 'owned_by', 'user1');
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new ship instances", function(){
        Omega.Ship.owned_by('user1', node, retrieval_cb);
        invoke_spy.getCall(0).args[5]({result : [{id: 'sh1'},{id: 'sh2'}]});
        var ships = retrieval_cb.getCall(0).args[0];
        assert(ships.length).equals(2);
        assert(ships[0]).isOfType(Omega.Ship);
        assert(ships[0].id).equals('sh1');
        assert(ships[1]).isOfType(Omega.Ship);
        assert(ships[1].id).equals('sh2');
      });
    });
  });
});}); // Omega.Ship
