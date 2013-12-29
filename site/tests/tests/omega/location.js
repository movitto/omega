pavlov.specify("Omega.Location", function(){
describe("Omega.Location", function(){
  it("converts movement strategy from json", function(){
    var loc =
      new Omega.Location({movement_strategy :
        {json_class : 'Motel::MovementStrategies::Linear', data : {speed: 50}}});
    assert(loc.movement_strategy.json_class).equals('Motel::MovementStrategies::Linear');
    assert(loc.movement_strategy.speed).equals(50);
  });

  describe("#toJSON", function(){
    it("returns location in json format", function(){
      var expected = {json_class : 'Motel::Location', id : 'l43',
                      x : 50, y : -50, z : 100, parent_id : 42,
                      movement_strategy : {}};
      var loc = new Omega.Location(expected);
      assert(loc.toJSON()).isSameAs(expected);
    });
  });

  describe("#clone", function(){
    it("returns cloned location", function(){
      var loc = new Omega.Location({x : 42});
      var loc2 = loc.clone();
      assert(loc2).isNotEqualTo(loc);
      assert(loc2).isSameAs(loc);
    })
  });

  describe("#distance_from", function(){
    it("returns distance from location to specified coordiante", function(){
      var l1 = new Omega.Location({x:0,y:0,z:0});
      var l2 = new Omega.Location({x:10,y:0,z:0});
      var l3 = new Omega.Location({x:0,y:10,z:0});
      var l4 = new Omega.Location({x:0,y:0,z:10});
      assert(l1.distance_from(l2)).equals(10)
      assert(l1.distance_from(l3)).equals(10)
      assert(l1.distance_from(l4)).equals(10)
    });
  });

  describe("#is_within", function(){
    describe("location is within distance of other location", function(){
      it("returns true", function(){
        var l1 = new Omega.Location({x:0,y:0,z:0})
        var l2 = new Omega.Location({x:0,y:0,z:1})
        assert(l1.is_within(10, l2)).isTrue();
      });
    });

    describe("location is not within distance of other location", function(){
      it("returns false", function(){
        var l1 = new Omega.Location({x:0,y:0,z:0})
        var l2 = new Omega.Location({x:0,y:0,z:100})
        assert(l1.is_within(10, l2)).isFalse();
      });
    });
  });

  describe("#to_s", function(){
    it("returns location coordinates in string format", function(){
      var loc = new Omega.Location({x:11, y:22, z:-3});
      assert(loc.to_s()).equals('11/22/-3');
    });
  });

  describe("#orientation_s", function(){
    it("returns location orientation in string format", function(){
      var loc = new Omega.Location({orientation_x:0,
                                    orientation_y:0,
                                    orientation_z:1});
      assert(loc.orientation_s()).equals('0/0/1');
    });
  });

  describe("#rotation_matrix", function(){
    it("creates rotation matrix from location's orientation", function(){
      var loc = new Omega.Location({orientation_x: 1, orientation_y : 0, orientation_z : 0});
      assert(loc.rotation_matrix().elements).areCloseTo([0,0,-1,0,0,1,0,0,1,0,0,0,0,0,0,1], 5);

      var loc = new Omega.Location({orientation_x: 0, orientation_y : 0, orientation_z : 1});
      assert(loc.rotation_matrix().elements).areCloseTo([1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1], 5);

      var loc = new Omega.Location({orientation_x: 0, orientation_y : 1, orientation_z : 0});
      assert(loc.rotation_matrix().elements).areCloseTo([1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1], 5);
    });
  });
});}); // Omega.Location
