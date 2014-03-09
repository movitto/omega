pavlov.specify("Omega.Station", function(){
describe("Omega.Station", function(){
  var station;

  before(function(){
    station = Omega.Gen.station({system_id : 'system1'});
  });

  it("sets parent_id = to system_id", function(){
    assert(station.parent_id).equals(station.system_id);
  });

  it("converts location", function(){
    var loc = {json_class: 'Motel::Location', y : -42};
    var station = new Omega.Station({location : loc});
    assert(station.location).isOfType(Omega.Location);
    assert(station.location.y).equals(-42);
  });

  //it("updates resources"); /// NIY test update_resources is invoked

  describe("#belongs_to_user", function(){
    it("returns bool indicating if station belongs to user", function(){
      station.user_id = 'user1';
      assert(station.belongs_to_user('user1')).isTrue();
      assert(station.belongs_to_user('user2')).isFalse();
    });
  });

  describe("#alive", function(){
    it("returns true", function(){
      assert(new Omega.Station().alive()).isTrue();
    });
  });

  describe("update_system", function(){
    it("sets solar_system", function(){
      var st = new Omega.Station();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      st.update_system(sys);
      assert(st.solar_system).equals(sys);
    });

    it("sets system_id", function(){
      var st = new Omega.Station();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      st.update_system(sys);
      assert(st.system_id).equals(sys.id);
    });

    it("sets parent_id", function(){
      var st = new Omega.Station();
      var sys = new Omega.SolarSystem({id : 'sys1'});
      st.update_system(sys);
      assert(st.parent_id).equals(sys.id);
    });
  });

  describe("#in_system", function(){
    var st, sys;
    before(function(){
      st  = new Omega.Station();
      sys = new Omega.SolarSystem({id : 'sys1'});
      st.update_system(sys);
    });

    describe("station is in system", function(){
      it("returns true", function(){
        assert(st.in_system(sys.id)).isTrue();
      });
    });

    describe("station is not in system", function(){
      it("returns false", function(){
        assert(st.in_system('foobar')).isFalse();
      });
    });
  });


  describe("#_update_resources", function(){
    it("converts resources from json data", function(){
      var station = new Omega.Station({resources : [{data : {material_id : 'steel'}},
                                                    {data : {material_id : 'plastic'}}]});
      assert(station.resources.length).equals(2);
      assert(station.resources[0].material_id).equals('steel');
      assert(station.resources[1].material_id).equals('plastic');
    });
  });

  describe("#selected", function(){
    it("sets mesh material emissive", function(){
      var station = Omega.Test.Canvas.Entities().station;
      station.selected(Omega.Test.Page());
      assert(station.mesh.tmesh.material.emissive.getHex()).equals(0xff0000);
    });
  });

  describe("#unselected", function(){
    it("resets mesh material emissive", function(){
      var station = Omega.Test.Canvas.Entities().station;
      station.unselected(Omega.Test.Page());
      assert(station.mesh.tmesh.material.emissive.getHex()).equals(0);
    })
  });

  describe("#owned_by", function(){
    var node, retrieval_cb;

    before(function(){
      node = new Omega.Node();
      retrieval_cb = sinon.spy();
      sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Station.owned_by('user1', node, retrieval_cb);
      sinon.assert.calledWith(node.http_invoke, 'manufactured::get_entities',
        'of_type', 'Manufactured::Station', 'owned_by', 'user1', sinon.match.func);
    });

    describe("cosmos::get_entity callback", function(){
      it("invokes callback", function(){
        Omega.Station.owned_by('user1', node, retrieval_cb);
        node.http_invoke.omega_callback()({});
        sinon.assert.called(retrieval_cb);
      });

      it("creates new station instances", function(){
        Omega.Station.owned_by('user1', node, retrieval_cb);
        node.http_invoke.omega_callback()({result : [{id: 'st1'},{id: 'st2'}]});
        var stations = retrieval_cb.getCall(0).args[0];
        assert(stations.length).equals(2);
        assert(stations[0]).isOfType(Omega.Station);
        assert(stations[0].id).equals('st1');
        assert(stations[1]).isOfType(Omega.Station);
        assert(stations[1].id).equals('st2');
      });
    });
  });

  describe("#under", function(){
    var node, retrieval_cb;

    before(function(){
      node         = new Omega.Node();
      retrieval_cb = sinon.spy();
      sinon.stub(node, 'http_invoke');
    });

    it("invokes manufactured::get_entities request", function(){
      Omega.Station.under('system1', node, retrieval_cb);
      sinon.assert.calledWith(node.http_invoke, 'manufactured::get_entities',
        'of_type', 'Manufactured::Station', 'under', 'system1', sinon.match.func);
    });

    describe("manufactured::get_entities callback", function(){
      it("invokes callback", function(){
        Omega.Station.under('system1', node, retrieval_cb);
        node.http_invoke.omega_callback()({});
        sinon.assert.called(retrieval_cb);
      });

      it("converts results to station instances", function(){
        Omega.Station.under('system1', node, retrieval_cb);
        node.http_invoke.omega_callback()({result : [{id : 'st1'}]});
        var stations = retrieval_cb.getCall(0).args[0];
        assert(stations.length).equals(1);
        assert(stations[0]).isOfType(Omega.Station);
        assert(stations[0].id).equals('st1');
      });
    });
  });
});}); // Omega.Station
