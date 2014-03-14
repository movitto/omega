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
  var ms, entity;

  before(function(){
    ms  = {e : 0, p : 10, speed: 1.57,
           dmajx: 0, dmajy : 1, dmajz : 0,
           dminx: 0, dminy : 0, dminz : 1};
    var loc = new Omega.Location({id : 42, movement_strategy : ms});

    entity  = $.extend({location : loc}, Omega.OrbitHelpers);
  });

  describe("#_calc_orbit", function(){
    it("sets entity orbit properties", function(){
      entity._calc_orbit();

      var orbit_axis = Omega.Math.cp(ms.dmajx, ms.dmajy, ms.dmajz,
                                     ms.dminx, ms.dminy, ms.dminz);
      orbit_axis = Omega.Math.nrml(orbit_axis[0], orbit_axis[1], orbit_axis[2]);

      assert(entity.orbit_axis[0]).equals(orbit_axis[0]);
      assert(entity.orbit_axis[1]).equals(orbit_axis[1]);
      assert(entity.orbit_axis[2]).equals(orbit_axis[2]);
      assert(entity.orbit.length).equals(361);
    });
  });

  describe("#_closest_orbit_point", function(){
    //it("returns point on orbit closest to entity location") // NIY
  });

  describe("#_loc_on_orbit", function(){
    describe("location is same as _closest_orbit_point", function(){
      //it("returns true"); // NIY
    });

    describe("location is not same as _closest_orbit_point", function(){
      //it("returns false"); // NIY
    });
  });

  describe("#_adjust_loc_to_orbit", function(){
    //it("sets entity location from closet orbit point"); // NIY
  });

  describe("_orbit_loc", function(){
    //it("rotates location by specified angle around orbit axis"); // NIY
  });

  describe("#_has_orbit_line", function(){
    var entity, line;
    before(function(){
      line = new Omega.OrbitLine({orbit : []});
      entity  = $.extend({orbit_line : line, components : []},
                         Omega.OrbitHelpers);
    });

    describe("#orbit line part of entity gfx components", function(){
      it("returns true", function(){
        entity.components.push(line.line);
        assert(entity._has_orbit_line()).isTrue();
      });
    });

    describe("#orbit line not part of entity gfx components", function(){
      it("returns false", function(){
        assert(entity._has_orbit_line()).isFalse();
      });
    });
  });

  describe("#add_orbit_line", function(){
    var entity;
    before(function(){
      entity  = $.extend({orbit: [], components : []}, Omega.OrbitHelpers);
    });

    it("creates new orbit line", function(){
      entity._add_orbit_line();
      assert(entity.orbit_line).isOfType(Omega.OrbitLine);
    });

    it("adds orbit line to entity gfx components", function(){
      entity._add_orbit_line();
      assert(entity._has_orbit_line()).isTrue();
    });
  });

  describe("#_rm_orbit_line", function(){
    var entity;
    before(function(){
      entity  = $.extend({orbit: [], components : []}, Omega.OrbitHelpers);
    });


    it("removes orbit line from entity gfx components", function(){
      entity._add_orbit_line();
      entity._rm_orbit_line();
      assert(entity._has_orbit_line()).isFalse();
    });
  });
});});
