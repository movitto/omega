pavlov.specify("Omega.Location", function(){
describe("Omega.Location", function(){
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

  describe("#rotation_matrix", function(){
    it("creates rotation matrix from location's orientation");
  });
});}); // Omega.Location
