/* Omega Orbit Helpers & Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
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
  /// default orbit's focus is at origin
  _orbit_center : function(){
    var ms = this.location.movement_strategy;
    return [-1 * ms.dmajx * this.le,
            -1 * ms.dmajy * this.le,
            -1 * ms.dmajz * this.le];
  },

  // orbit calculated on a per-entity basis
  _calc_orbit : function(){
    if(!this.location || !this.location.movement_strategy){
      this.orbit = [];
      return;
    }

    var ms = this.location.movement_strategy;

    /// base elliptical path properties
    var intercepts = Omega.Math.intercepts(ms.e, ms.p)
    this.a     = intercepts[0];
    this.b     = intercepts[1];
    this.le    = Omega.Math.le(this.a, this.b);
    var center = this._orbit_center();
    this.cx = center[0]; this.cy = center[1]; this.cz = center[2];

    /// normal vector of orbit axis'
    var nv = Omega.Math.cp(ms.dmajx, ms.dmajy, ms.dmajz,
                           ms.dminx, ms.dminy, ms.dminz);

    /// the axis-angle which the standard cartesian plane has been
    /// rotates to form orbit plane
    this.rot_plane = {};
    this.rot_plane.angle = Omega.Math.abwn(0, 0, 1, nv[0], nv[1], nv[2]);
    if(this.rot_plane.angle == 0) this.rot_plane.axis = [1,0,0];
    else this.rot_plane.axis  = Omega.Math.cp(0, 0, 1, nv[0], nv[1], nv[2]);
    this.rot_plane.axis  = Omega.Math.nrml(this.rot_plane.axis[0],
                                           this.rot_plane.axis[1],
                                           this.rot_plane.axis[2]);

    /// new standard cartesian major axis on rotated orbit plane
    var nmaj = Omega.Math.rot(1, 0, 0,
                              this.rot_plane.angle,
                              this.rot_plane.axis[0],
                              this.rot_plane.axis[1],
                              this.rot_plane.axis[2]);

    /// the axis angle which the major axis was rotated on orbit plane
    /// to form orbit major axis
    this.rot_axis = {};
    this.rot_axis.angle = Omega.Math.abwn(nmaj[0],  nmaj[1],  nmaj[2],
                                          ms.dmajx, ms.dmajy, ms.dmajz);
    if(this.rot_axis.angle == 0)
      this.rot_axis.axis = [0,1,0];
    else
      this.rot_axis.axis = Omega.Math.cp(nmaj[0],  nmaj[1],  nmaj[2],
                                         ms.dmajx, ms.dmajy, ms.dmajz);
    this.rot_axis.axis = Omega.Math.nrml(this.rot_axis.axis[0],
                                         this.rot_axis.axis[1],
                                         this.rot_axis.axis[2]);

    /// TODO optimize, combine rot_plane & rot_axis to form single rotational
    /// matrix which can be applied to coords to transform
    /// (from 2D ellipse to 3D pos & back)

    /// calculate a fixed set of orbit points to render w/ line
    this.orbit = Omega.Math.elliptical_path(ms);
  },

  /// Return current angle on orbit which location resides
  _orbit_angle_from_coords : function(x, y, z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location'){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    var n = Omega.Math.rot(x-this.cx, y-this.cy, z-this.cz,
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
    var projection = x/this.a;
    if(projection > 1) projection = 1;
    else if(projection < -1) projection = -1;
    var angle = Math.acos(projection)
    if(y < 0) angle = 2 * Math.PI - angle;

    return angle;
  },

  /// Set the location from the specified angle on the orbit path
  _coords_from_orbit_angle : function(new_angle){
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

    return [n[0] + this.cx, n[1] + this.cy, n[2] + this.cz];
  },

  /// Bool indicating if coords are on orbit
  _coords_on_orbit : function(coords, tolerance){
    var angle        = this._orbit_angle_from_coords(coords);
    var orbit_coords = this._coords_from_orbit_angle(angle);
    var dist         = Math.sqrt(Math.pow(coords[0] - orbit_coords[0], 2) +
                                 Math.pow(coords[1] - orbit_coords[1], 2) +
                                 Math.pow(coords[2] - orbit_coords[2], 2));
    return dist < tolerance;
  },

  _has_orbit_line : function(){
    return !!(this.orbit_line) && (this.components.indexOf(this.orbit_line.line) != -1);
  },

  _add_orbit_line : function(color){
    this.orbit_line = new Omega.OrbitLine({orbit: this.orbit, color: color});
    /// XXX need to set scale incase starting to orbit after entity was added to scene
    if(this.scene_scale) this.orbit_line.line.scale.set(1/this.scene_scale,
                                                        1/this.scene_scale,
                                                        1/this.scene_scale);
    this.components.push(this.orbit_line.line);
  },

  _rm_orbit_line : function(){
    var i = this.components.indexOf(this.orbit_line.line);
    this.components.splice(i, 1);
  }
};
