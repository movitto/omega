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

});}); // Omega.Mission
