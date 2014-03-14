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
  // orbit calculated on the fly on a per-entity basis
  _calc_orbit : function(){
    if(!this.location || !this.location.movement_strategy){
      this.orbit = [];
      return;
    }
    var ms = this.location.movement_strategy;

    var intercepts = Omega.Math.intercepts(ms.e, ms.p)
    this.a  = intercepts[0]; this.b = intercepts[1];
    this.le = Omega.Math.le(this.a, this.b);
    var center = Omega.Math.center(ms.dmajx, ms.dmajy, ms.dmajz, this.le);
    this.cx = center[0]; this.cy = center[1]; this.cz = center[2];

    var nv = Omega.Math.cp(ms.dmajx, ms.dmajy, ms.dmajz,
                           ms.dminx, ms.dminy, ms.dminz);

    this.rot_plane = {};
    this.rot_plane.angle = Omega.Math.abwn(0, 0, 1, nv[0], nv[1], nv[2]);
    if(this.rot_plane.angle == 0) this.rot_plane.axis = [1,0,0];
    else this.rot_plane.axis  = Omega.Math.cp(0, 0, 1, nv[0], nv[1], nv[2]);
    this.rot_plane.axis  = Omega.Math.nrml(this.rot_plane.axis[0],
                                           this.rot_plane.axis[1],
                                           this.rot_plane.axis[2]);

    var nmaj = Omega.Math.rot(1, 0, 0,
                              this.rot_plane.angle,
                              this.rot_plane.axis[0],
                              this.rot_plane.axis[1],
                              this.rot_plane.axis[2]);

    this.rot_axis = {};
    this.rot_axis.angle = Omega.Math.abwn(nmaj[0],  nmaj[1],  nmaj[2],
                                          ms.dmajx, ms.dmajy, ms.dmajz);
    this.rot_axis.axis = Omega.Math.cp(nmaj[0],  nmaj[1],  nmaj[2],
                                       ms.dmajx, ms.dmajy, ms.dmajz);
    this.rot_axis.axis = Omega.Math.nrml(this.rot_axis.axis[0],
                                         this.rot_axis.axis[1],
                                         this.rot_axis.axis[2]);

    this.orbit = Omega.Math.elliptical_path(ms);
  },

  _current_orbit_angle : function(){
    var n = Omega.Math.rot(this.location.x-this.cx,
                           this.location.y-this.cy,
                           this.location.z-this.cz,
                             - this.rot_axis.angle,
                             this.rot_axis.axis[0],
                             this.rot_axis.axis[1],
                             this.rot_axis.axis[2])

        n = Omega.Math.rot(n[0], n[1], n[2],
                        -this.rot_plane.angle,
                            this.rot_plane.axis[0],
                            this.rot_plane.axis[1],
                            this.rot_plane.axis[2]);

    var x = n[0] ; var y = n[1]; /// z should == 0

    // calc current angle (x = a*Math.cos(i))
    var angle = Math.acos(x/this.a)
    if(y < 0) angle = 2 * Math.PI - angle;

    return angle;
  },

  _set_orbit_angle : function(new_angle){
    var x = this.a * Math.cos(new_angle);
    var y = this.b * Math.sin(new_angle);
    var n = Omega.Math.rot(x, y, 0,
                  this.rot_plane.angle,
                this.rot_plane.axis[0],
                this.rot_plane.axis[1],
                this.rot_plane.axis[2])


        n = Omega.Math.rot(n[0], n[1], n[2],
                        this.rot_axis.angle,
                      this.rot_axis.axis[0],
                      this.rot_axis.axis[1],
                      this.rot_axis.axis[2]);

    this.location.x = n[0] + this.cx;
    this.location.y = n[1] + this.cy;
    this.location.z = n[2] + this.cz;
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
