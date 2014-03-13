/* Omega Orbit Helpers & Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// Line used to render and entity's orbit
Omega.OrbitLine = function(args){
  if(!args) args = {};
  var orbit = args['orbit'];
  var color = args['color'] || this.default_color;
  this.init_gfx(orbit, color)
};

Omega.OrbitLine.prototype = {
  default_color : 0xAAAAAA,

  _geometry : function(orbit){
    var orbit_geo = new THREE.Geometry();
    var first = null, last = null;
    for(var o = 1; o < orbit.length; o++){
      var corbit  = orbit[o];
      var corbitv = new THREE.Vector3(corbit[0], corbit[1], corbit[2]);
      last = corbitv;

      var porbit  = orbit[o-1];
      var porbitv = new THREE.Vector3(porbit[0], porbit[1], porbit[2]);
      if(first == null) first = porbitv;

      orbit_geo.vertices.push(corbitv);
      orbit_geo.vertices.push(porbitv);
    }

    orbit_geo.vertices.push(first);
    orbit_geo.vertices.push(last);
    return orbit_geo;
  },

  _material : function(color){
    return new THREE.LineBasicMaterial({color: color})
  },

  init_gfx : function(orbit, color){
    this.line  = new THREE.Line(this._geometry(orbit), this._material(color));
  }
};

/// Mixin adding helper methods to assist w/ orbits
Omega.OrbitHelpers = {
  /// orbit calculated on the fly on a per-entity basis
  _calc_orbit : function(){
    if(!this.location || !this.location.movement_strategy){
      this.orbit = [];
      return;
    }

    var ms = this.location.movement_strategy;
    this.orbit_axis =
      Omega.Math.cp(ms.dmajx, ms.dmajy, ms.dmajz,
                    ms.dminx, ms.dminy, ms.dminz);
    this.orbit_axis =
      Omega.Math.nrml(this.orbit_axis[0],
                      this.orbit_axis[1],
                      this.orbit_axis[2]);

    this.orbit = Omega.Math.elliptical_path(ms);
  },

  _closest_orbit_point : function(){
    var d = null, result = null;
    for(var o = 0; o < this.orbit.length; o++){
      var point = this.orbit[o]
      var od = this.location.distance_from(point[0], point[1], point[2]);
      if(d == null || od < d){
        result = point;
        d = od;
      }
    }

    return result;
  },

  _loc_on_orbit : function(){
    var closest = this._closest_orbit_point();
    return this.location.distance_from(closest[0], closest[1], closest[2]) == 0;
  },

  _adjust_loc_to_orbit : function(){
    var closest = this._closest_orbit_point();
    this.location.set(closest[0], closest[1], closest[2]);
  },

  _orbit_loc : function(angle){
    var ncoords = Omega.Math.rot(this.location.x,
                                 this.location.y,
                                 this.location.z,
                                 angle,
                                 this.orbit_axis[0],
                                 this.orbit_axis[1],
                                 this.orbit_axis[2]);
    this.location.set(ncoords[0], ncoords[1], ncoords[2]);
  },

  _has_orbit_line : function(){
    return !!(this.orbit_line) && (this.components.indexOf(this.orbit_line.line) != -1);
  },

  _add_orbit_line : function(color){
    this.orbit_line = new Omega.OrbitLine({orbit: this.orbit, color: color});
    this.components.push(this.orbit_line.line);
  },

  _rm_orbit_line : function(){
    var i = this.components.indexOf(this.orbit_line.line);
    this.components.splice(i, 1);
  }
};
