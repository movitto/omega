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
                      orientation_x : 1, orientation_y : 0, orientation_z : 0,
                      movement_strategy : {}};
      var loc = new Omega.Location(expected);
      assert(loc.toJSON()).isSameAs(expected);
    });
  });

  describe("#vector", function(){
    it("returns THREE.Vector w/ location's coordinates", function(){
      var loc = new Omega.Location({x : 50, y : -40, z : 20.5});
      var vector = loc.vector();
      assert(vector).isOfType(THREE.Vector3);
      assert(vector.x).equals(50);
      assert(vector.y).equals(-40);
      assert(vector.z).equals(20.5);
    });
  });

  describe("#update", function(){
    it("updates location attributes from other location", function(){
      var loc = new Omega.Location({x:1, y:-2, z:3.3,
                                    orientation_x : 1,
                                    orientation_y : 0,
                                    orientation_z : 0,
                                    parent_id : 50});
      var target = new Omega.Location();
      target.update(loc);
      assert(target.x).equals(1);
      assert(target.y).equals(-2);
      assert(target.z).equals(3.3);
      assert(target.orientation_x).equals(1);
      assert(target.orientation_y).equals(0);
      assert(target.orientation_z).equals(0);
      assert(target.parent_id).equals(50);
    });

    it("updates location movement strategy", function(){
      var loc = new Omega.Location();
      loc.movement_strategy = {'movement' : 'strategy'};

      var target = new Omega.Location();
      sinon.stub(target, 'update_ms');

      target.update(loc);
      sinon.assert.calledWith(target.update_ms, loc.movement_strategy);
    });
  });

  describe("#update_ms", function(){
    it("sets movement strategy", function(){
      var loc = new Omega.Location();
      var ms  = {'movement' : 'strategy'};
      loc.update_ms(ms);
      assert(loc.movement_strategy).equals(ms);
    });

    it("sets movement strategy from json data", function(){
      var loc = new Omega.Location();
      var ms  = {'json_class' : 'Motel::MovementStrategies::Linear',
                 'data' : {'speed' : 50}};
      loc.update_ms(ms);
      assert(loc.movement_strategy.speed).equals(50);
      assert(loc.movement_strategy.json_class).equals('Motel::MovementStrategies::Linear')
      assert(loc.movement_strategy.data).isUndefined();
    });

    it("sets existing movement strategy from json data", function(){
      var loc = new Omega.Location();
      var ms  = {'json_class' : 'Motel::MovementStrategies::Linear',
                 'data' : {'speed' : 50}};
      loc.movement_strategy = ms;

      loc.update_ms();
      assert(loc.movement_strategy.speed).equals(50);
      assert(loc.movement_strategy.json_class).equals('Motel::MovementStrategies::Linear')
      assert(loc.movement_strategy.data).isUndefined();
    });
  });

  describe("#set", function(){
    it("sets individual coordinates", function(){
      var loc = new Omega.Location();
      loc.set(10, -20, -30.5);
      assert(loc.x).equals(10);
      assert(loc.y).equals(-20);
      assert(loc.z).equals(-30.5);
    });

    it("sets coordiantes from array", function(){
      var loc = new Omega.Location();
      loc.set([10, -20, -42.1]);
      assert(loc.x).equals(10);
      assert(loc.y).equals(-20);
      assert(loc.z).equals(-42.1);
    });
  });

  describe("#coordinates", function(){
    it("returns coordinates as an array", function(){
      var loc = new Omega.Location({x : 0, y : 1, z : 10});
      assert(loc.coordinates()).isSameAs([0, 1, 10]);
    });
  });

  describe("#orientation", function(){
    it("returns orientation array", function(){
      var loc = new Omega.Location({orientation_x : 0,
                                    orientation_y : 1,
                                    orientation_z : 0});
      assert(loc.orientation()).isSameAs([0,1,0]);
    });
  });

  describe("#orientation_vector", function(){
    it("returns THREE.Vector3 with orientation", function(){
      var loc = new Omega.Location({orientation_x : 0,
                                    orientation_y : 1,
                                    orientation_z : 0});
      var vector = loc.orientation_vector();
      assert(vector).isOfType(THREE.Vector3);
    });
  });

  describe("#set_orientation", function(){
    it("sets individual orientation components", function(){
      var loc = new Omega.Location();
      loc.set_orientation(0, 0, 1);
      assert(loc.orientation_x).equals(0);
      assert(loc.orientation_y).equals(0);
      assert(loc.orientation_z).equals(1);
    });

    it("sets orientation from an array", function(){
      var loc = new Omega.Location();
      loc.set_orientation([0, 0, 1]);
      assert(loc.orientation_x).equals(0);
      assert(loc.orientation_y).equals(0);
      assert(loc.orientation_z).equals(1);
    });
  });

  //describe("#orientation_difference", function(){
    //it("returns axis angle between orientation and specified coordinate"); // NIY
  //});

  //describe("#rotation_to", function(){
    ///it("returns the orientation difference to orientation facing specified coordinate"); // NIY
  //});

  //describe("#facing", function(){
  //describe("rotation_to is less than specified tolerance", function(){
  //it("returns true"); /// NIY
  //});
  //describe("rotation_to is less than specified toleration", function(){
  //it("returns false"); /// NIY
  //});
  //});

  describe("#add", function(){
    it("adds/returns coordinates + values", function(){
      var loc = new Omega.Location({x:10,y:9,z:-8});
      var result = loc.add(10, -5, 3);
      assert(result).isOfType(Omega.Location);
      assert(result.coordinates()).isSameAs([20, 4, -5]);
    });
  });

  describe("#sub", function(){
    it("returns coordinates minus specified values", function(){
      var loc = new Omega.Location({x:10,y:9,z:-8});
      assert(loc.sub(10, -5, 3)).isSameAs([0, 14, -11]);
      assert(loc.coordinates()).isSameAs([10, 9, -8]);
    });
  });

  describe("#divide", function(){
    it("divides/returns coordinates by scalar", function(){
      var loc = new Omega.Location({x:10,y:20,z:-30});
      var result = loc.divide(5);
      assert(result).isSameAs([2,4,-6]);
    });
  });

  describe("#direction_to", function(){
    it("returns orientation from location to target", function(){
      var loc = new Omega.Location({x: 10, y: 0, z: 0});
      assert(loc.direction_to(0, 0, 0)).isSameAs([-1, 0, 0]);
      assert(loc.direction_to(10, 10, 0)).isSameAs([0, 1, 0]);
      assert(loc.direction_to(10, 0, -1)).isSameAs([0, 0, -1]);
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

  describe("#length", function(){
    it("returns the distance coordinates are from origin", function(){
      var loc = new Omega.Location({x: 10, y: 10, z: 10});
      assert(Omega.Math.round_to(loc.length(), 2)).equals(17.32);
    });
  });

  describe("#is_stopped", function(){
    describe("location movement strategy is stopped", function(){
      it("returns true", function(){
        var loc = new Omega.Location({movement_strategy :
                   {json_class : 'Motel::MovementStrategies::Stopped'}});
        assert(loc.is_stopped()).isTrue();
      });
    });

    it("returns false", function(){
      var loc = new Omega.Location({movement_strategy :
                 {json_class : 'Motel::MovementStrategies::Linear'}});
      assert(loc.is_stopped()).isFalse();
    });
  });

  describe("#is_moving", function(){
    describe("location is moving using specified strategy", function(){
      it("returns true", function(){
        var loc = new Omega.Location({movement_strategy:
                    {json_class : 'Motel::MovementStrategies::Linear'}});
        assert(loc.is_moving('linear')).isTrue();
      });
    });

    describe("location is not moving using specified strategy", function(){
      it("returns false", function(){
        var loc = new Omega.Location({movement_strategy:
                    {json_class : 'Motel::MovementStrategies::Linear'}});
        assert(loc.is_moving('rotate')).isFalse();
      });
    });
  });

  describe("#ms_dir", function(){
    it("returns movement strategy velocity", function(){
      var loc = new Omega.Location({movement_strategy : {dx : -1, dy : 0, dz : 0}});
      assert(loc.ms_dir()).isSameAs([-1, 0, 0]);
    });
  });

  describe("#ms_acceleration", function(){
    it("returns movement strategy acceleration", function(){
      var loc = new Omega.Location({movement_strategy : {ax : 1, ay : 0, az : 0}});
      assert(loc.ms_acceleration()).isSameAs([1, 0, 0]);
    });
  });

  describe("#update_ms_dir", function(){
    it("updates movement strategy velocity with specified direction", function(){
      var loc = new Omega.Location({movement_strategy : {}});
      loc.update_ms_dir([0, 1, 0]);
      assert(loc.ms_dir()).isSameAs([0, 1, 0]);
    });

    it("updates movement strategy velocity with location orientation", function(){
      var loc = new Omega.Location({movement_strategy : {}});
      loc.set_orientation(0, 0, -1);
      loc.update_ms_dir();
      assert(loc.ms_dir()).isSameAs([0, 0, -1]);
    });
  });

  describe("#update_ms_acceleration", function(){
    it("updates movement strategy acceleration with specified direction", function(){
      var loc = new Omega.Location({movement_strategy : {}});
      loc.update_ms_acceleration([0, 1, 0]);
      assert(loc.ms_acceleration()).isSameAs([0, 1, 0]);
    });

    it("updates movement strategy acceleration with location orientation", function(){
      var loc = new Omega.Location({movement_strategy : {}});
      loc.set_orientation(0, 0, -1);
      loc.update_ms_acceleration();
      assert(loc.ms_acceleration()).isSameAs([0, 0, -1]);
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
      assert(loc.to_s()).equals('1.10e+1/2.20e+1/-3.00e+0');
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

  describe("#set_tracking", function(){
    it("sets tracking location", function(){
      var loc = new Omega.Location();
      var tracking = new Omega.Location();
      loc.set_tracking(tracking);
      assert(loc.tracking).equals(tracking);
    });
  });

  describe("#near_target", function(){
    var loc, tracking;

    before(function(){
      loc = new Omega.Location({movement_strategy : {distance : 10}});
      tracking = new Omega.Location();
    });

    describe("location is not tracking", function(){
      it("returns true", function(){
        assert(loc.near_target()).isTrue();
      });
    });

    describe("distance from target is less than specified distance", function(){
      it("returns true", function(){
        loc.set_tracking(tracking);
        loc.set(0, 0, 0);
        tracking.set(10, 0, 0);
        assert(loc.near_target(20)).isTrue();
      });
    });

    describe("distance from target is less than movement strategy distance", function(){
      it("returns true", function(){
        loc.set_tracking(tracking);
        loc.set(0, 0, 0);
        tracking.set(5, 0, 0);
        assert(loc.near_target()).isTrue();
      });
    });

    describe("distance from target is greater than specified distance", function(){
      it("returns false", function(){
        loc.set_tracking(tracking);
        loc.set(0, 0, 0);
        tracking.set(15, 0, 0);
        assert(loc.near_target(10)).isFalse();
      });
    });

    describe("distance from target is greater than movement strategy distance", function(){
      it("returns false", function(){
        loc.set_tracking(tracking);
        loc.set(0, 0, 0);
        tracking.set(15, 0, 0);
        assert(loc.near_target()).isFalse();
      });
    });
  });

  describe("#distance_from_target", function(){
    it("returns distance location is from target", function(){
      var loc = new Omega.Location();
      var tracking = new Omega.Location();
      loc.set_tracking(tracking);
      loc.set(0, 0, 0);
      tracking.set(15, 0, 0);
      assert(loc.distance_from_target()).equals(15);
    });
  });

  describe("#direction_to_target", function(){
    it("returns direction from location to target", function(){
      var loc = new Omega.Location();
      var tracking = new Omega.Location();
      loc.set_tracking(tracking);
      loc.set(0, 0, 0);
      tracking.set(-25, 0, 0);
      assert(loc.direction_to_target()).isSameAs([-1, 0, 0]);
    });
  });

  describe("#rotation_to_target", function(){
    it("returns rotation from location to target", function(){
      var loc = new Omega.Location();
      var tracking = new Omega.Location();
      loc.set_tracking(tracking);
      loc.set(0, 0, 0);
      loc.set_orientation(0, 0, 1);
      tracking.set(10, 0, 0);
      assert(loc.rotation_to_target()).isSameAs([Math.PI/2, 0, 1, 0]);
    });
  });

  describe("#angle_to_target", function(){
    it("return angle from location to target", function(){
      var loc = new Omega.Location();
      var tracking = new Omega.Location();
      loc.set_tracking(tracking);
      loc.set(0, 0, 0);
      loc.set_orientation(0, 0, 1);
      tracking.set(10, 0, 0);
      assert(loc.angle_to_target()).equals(Math.PI/2);
    });
  });

  describe("#facing_target", function(){
    describe("angle to target is less than tolerance", function(){
      it("returns true", function(){
        var loc = new Omega.Location();
        var tracking = new Omega.Location();
        loc.set_tracking(tracking);
        loc.set(0, 0, 0);
        loc.set_orientation(0, 0, 1);
        tracking.set(10, 0, 0);
        assert(loc.facing_target(Math.PI)).isTrue();
      });
    });

    describe("angle to target is greater than tolerance", function(){
      it("returns false", function(){
        var loc = new Omega.Location();
        var tracking = new Omega.Location();
        loc.set_tracking(tracking);
        loc.set(0, 0, 0);
        loc.set_orientation(0, 0, 1);
        tracking.set(10, 0, 0);
        assert(loc.facing_target(Math.PI/4)).isFalse();
      });
    });
  });
});}); // Omega.Location
