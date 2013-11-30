pavlov.specify("Omega.Station", function(){
describe("Omega.Station", function(){
  var station, page;

  before(function(){
    station = new Omega.Station({id : 'station1', user_id : 'user1',
                    location  : new Omega.Location({x:99,y:-2,z:100}),
                    resources : [{quantity : 50, material_id : 'gold'},
                                 {quantity : 25, material_id : 'ruby'}]});
    page = new Omega.Pages.Test({canvas: Omega.Test.Canvas()});
  });

  describe("#belongs_to_user", function(){
    it("returns bool indicating if station belongs to user", function(){
      assert(station.belongs_to_user('user1')).isTrue();
      assert(station.belongs_to_user('user2')).isFalse();
    });
  });

  describe("#retrieve_details", function(){
    var details_cb;

    before(function(){
      details_cb = sinon.spy();
    });

    it("invokes details cb with station id, location, resources and construction command", function(){
      var text = ['Station: station1<br/>',
                  '@ 99/-2/100<br/>'      ,
                  'Resources:<br/>'       ,
                  '50 of gold<br/>'       ,
                  '25 of ruby<br/>'      ];

      station.retrieve_details(page, details_cb);
      sinon.assert.called(details_cb);

      var details = details_cb.getCall(0).args[0];
      assert(details[0]).equals(text[0]);
      assert(details[1]).equals(text[1]);
      assert(details[2]).equals(text[2]);
      assert(details[3]).equals(text[3]);
      assert(details[4]).equals(text[4]);
      var cmd = details[5];
      assert(cmd[0].id).equals('station_construct_station1');
      assert(cmd[0].className).equals('station_construct');
      assert(cmd.text()).equals('construct');
    });

    it("sets station in construction command data", function(){
      station.retrieve_details(page, details_cb);
      $('#qunit-fixture').append(details_cb.getCall(0).args[0]);
      assert($('#station_construct_station1').data('station')).equals(station);
    });

    it("handles construction command click event", function(){
      station.retrieve_details(page, details_cb);
      var construct = details_cb.getCall(0).args[0][5];
      assert(construct).handles('click');
    });
  });

  describe("#selected", function(){
    it("sets mesh material emissive", function(){
      var station = Omega.Test.Canvas.Entities().station;
      station.selected(Omega.Test.Page());
      assert(station.mesh.material.emissive.getHex()).equals(0xff0000);
    });
  });

  describe("#unselected", function(){
    it("resets mesh material emissive", function(){
      var station = Omega.Test.Canvas.Entities().station;
      station.unselected(Omega.Test.Page());
      assert(station.mesh.material.emissive.getHex()).equals(0);
    })
  });

  describe("#construct", function(){
    before(function(){
      page.node = new Omega.Node();
    });

    it("invokes manufactured::construct_entity", function(){
      var http_invoke = sinon.spy(page.node, 'http_invoke');
      station._construct(page);
      sinon.assert.calledWith(http_invoke, 'manufactured::construct_entity',
                  station.id, 'entity_type', 'Ship', 'type', 'mining', 'id');
      /// TODO match uuid
    });

    describe("on manufactured::construct_entity response", function(){
      var ship, station2, system;
      var handler, error_response, success_response;

      before(function(){
        var spy = sinon.stub(page.node, 'http_invoke');
        station._construct(page);
        handler = spy.getCall(0).args[8];

        system  = new Omega.SolarSystem({id : 'system1'});
        ship    = new Omega.Ship({parent_id : 'system1'});
        station2 = new Omega.Station({resources :
                    [{quantity : 5, material_id : 'diamond'}]});

        error_response = {error : {message : "construct_error"}};
        success_response = {result : [station2, ship]};
      });

      after(function(){
        Omega.UI.Dialog.remove();
      });

      describe("error during command", function(){
        it("sets command dialog title", function(){
          handler(error_response);
          assert(station.dialog().title).equals('Construction Error');
        });

        it("shows command dialog", function(){
          var show = sinon.spy(station.dialog(), 'show_error_dialog');
          handler(error_response);
          sinon.assert.called(show);
          assert(station.dialog().component()).isVisible();
        });

        it("appends error to command dialog", function(){
          var append_error = sinon.spy(station.dialog(), 'append_error');
          handler(error_response);
          sinon.assert.calledWith(append_error, 'construct_error');
          assert($('#command_error').html()).equals('construct_error');
        });
      });

      describe("successful command response", function(){
        after(function(){
          if(page.canvas.add.restore) page.canvas.add.restore();
          if(page.canvas.entity_container.refresh.restore) page.canvas.entity_container.refresh.restore();
          page.canvas.clear();
        });

        it("processes constructed ship", function(){
          var process_entity = sinon.spy(page, 'process_entity');
          handler(success_response)
          sinon.assert.calledWith(process_entity, ship);
        });

        describe("constructed ship is in scene system", function(){
          it("adds ship to scene", function(){
            page.canvas.set_scene_root(system);
            var add = sinon.stub(page.canvas, 'add');
            handler(success_response);
            sinon.assert.calledWith(add, ship);
          });
        });

        it("updates station resources", function(){
          handler(success_response);
          assert(station.resources).isSameAs(station2.resources);
        });

        it("refreshes entity container", function(){
          var refresh = sinon.spy(page.canvas.entity_container, 'refresh');
          handler(success_response);
          sinon.assert.called(refresh);
        });
      });
    });
  });

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
