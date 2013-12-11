pavlov.specify("Omega.Mission", function(){
describe("Omega.Mission", function(){
  describe("#expires", function(){
    it("returns Date which mission expires at", function(){
      var m = new Omega.Mission({timeout : 30,
                                 assigned_time :  "2013-07-03 01:58:08"})
      assert(m.expires().toString()).equals(new Date(Date.parse("2013/07/03 01:58:38")).toString());
    });
  });

  describe("#expired", function(){
    describe("mission expired", function(){
      it("returns true", function(){
        var m = new Omega.Mission({timeout : 30,
                                   assigned_time :  "1900-07-03 01:58:08"});
        assert(m.expired()).isTrue();
      })
    });

    describe("mission not expired", function(){
      it("returns false", function(){
        var m = new Omega.Mission();
        assert(m.expired()).isFalse();
      })
    });
  });

  describe("#unassigned", function(){
    describe("mission is not assigned", function(){
      it("returns true", function(){
        var m = new Omega.Mission();
        assert(m.unassigned()).isTrue();
      });
    });

    describe("mission is assigned", function(){
      it("returns false", function(){
        var m = new Omega.Mission({assigned_to_id: 'user1'});
        assert(m.unassigned()).isFalse();
      });
    });
  });

  describe("#assigned_to", function(){
    describe("assigned_to_id is same as specified user's", function(){
      it("returns true", function(){
        var m = new Omega.Mission({assigned_to_id : 'test'})
        assert(m.assigned_to('test')).isTrue();
      });
    });

    describe("assigned_to_id is not same as specified user's", function(){
      it("returns false", function(){
        var m = new Omega.Mission({assigned_to_id : 'test'})
        assert(m.assigned_to('foobar')).isFalse();
      });
    });
  });

  describe("#assign_to", function(){
    it("invokes missions::assign_mission request", function(){
      var mission = new Omega.Mission({id: 'mission1'});
      var node    = new Omega.Node();
      var cb      = sinon.spy();

      var spy     = sinon.spy(node, 'http_invoke');
      mission.assign_to('user1', node, cb);
      sinon.assert.calledWith(spy, 'missions::assign_mission', 'mission1', 'user1', cb);
    });
  });

  describe("#all", function(){
    it("invokes missions::get_missions request", function(){
      var node = new Omega.Node();
      var spy  = sinon.spy(node, 'http_invoke');
      var cb   = sinon.spy();
      Omega.Mission.all(node, cb);
      sinon.assert.calledWith(spy, 'missions::get_missions', sinon.match.func);
    });

    describe("missions::get_missions callback", function(){
      var client_cb, get_cb;

      before(function(){
        var node = new Omega.Node();
        var stub  = sinon.stub(node, 'http_invoke');
        client_cb = sinon.spy();
        Omega.Mission.all(node, client_cb);
        get_cb   = stub.getCall(0).args[1];
      });

      it("invokes callback", function(){
        var response = {result: []};
        get_cb(response);
        sinon.assert.calledWith(client_cb, []);
      });

      it("creates new missions instances", function(){
        var response = {result : [{id: 'mission1'}, {id: 'mission2'}]};
        get_cb(response);

        var missions = client_cb.getCall(0).args[0];
        assert(missions[0]).isOfType(Omega.Mission);
        assert(missions[0].id).equals('mission1');
        assert(missions[1]).isOfType(Omega.Mission);
        assert(missions[1].id).equals('mission2');
      });

    });
  });

});}); // Omega.Mission
