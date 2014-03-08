pavlov.specify("Omega.OrbitLine", function(){
describe("Omega.OrbitLine", function(){
  it("has a THREE.Mesh instance", function(){
    var orbit_line = new Omega.OrbitLine({orbit : []});
    assert(orbit_line.line).isOfType(THREE.Line);
    assert(orbit_line.line.geometry).isOfType(THREE.Geometry);
    assert(orbit_line.line.material).isOfType(THREE.LineBasicMaterial);
    /// TODO verify actual vertices against a test orbit
  });
});});

pavlov.specify("Omega.OrbitHelpers", function(){
describe("Omega.OrbitHelpers", function(){
  var entity;

  before(function(){
    var ms  = {e : 0, p : 10, speed: 1.57,
               dmajx: 0, dmajy : 1, dmajz : 0,
               dminx: 0, dminy : 0, dminz : 1};
    var loc = new Omega.Location({id : 42, movement_strategy : ms});

    entity  = $.extend({location : loc}, Omega.OrbitHelpers);
  });

  describe("#_calc_orbit", function(){
    it("sets entity orbit properties", function(){
      entity._calc_orbit();

      assert(entity.a).equals(10);
      assert(entity.b).equals(10);
      assert(entity.le).equals(0);
      assert(entity.cx).equals(0);
      assert(entity.cy).equals(0);
      assert(entity.cz).equals(0);
      assert(entity.rot_plane.angle).close(1.57,2);
      assert(entity.rot_axis.angle).close(1.57,2);

      assert(entity.rot_plane.axis[0]).equals(0)
      assert(entity.rot_plane.axis[1]).equals(1)
      assert(entity.rot_plane.axis[2]).equals(0)
      assert(entity.rot_axis.axis[0]).equals(1)
      assert(entity.rot_axis.axis[1]).equals(0)
      assert(entity.rot_axis.axis[2]).close(0, 0.00001)
    });
  });

  describe("#_current_orbit_angle", function(){
    //it("returns current orbit angle from location and ms"); NIY
  });

  describe("#_set_orbit_angle", function(){
    //it("set location coords from orbit angle and location's ms"); NIY
  });

  describe("#_has_orbit_line", function(){
    describe("#orbit line part of entity gfx components", function(){
      //it("returns true") NIY
    });

    describe("#orbit line not part of entity gfx components", function(){
      //it("returns false") NIY
    });
  });

  describe("#add_orbit_line", function(){
    //it("creates new orbit line"); NIY
    //it("adds orbit line to entity gfx components") NIY
  });

  describe("#_rm_orbit_line", function(){
    //it("removes orbit line from entity gfx components") NIY
  });
});});
