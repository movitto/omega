/* Omega Location Orientation Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationOrientation = {
  /// Return location orientation in an array
  orientation : function(){
    return [this.orientation_x, this.orientation_y, this.orientation_z];
  },

  /// Return location orientation in a THREE.Vector3
  orientation_vector : function(){
    return new THREE.Vector3(this.orientation_x,
                             this.orientation_y,
                             this.orientation_z);
  },

  /// Set orientation,
  /// - accepts each component as an indivisual param: loc.set_orientation(0,0,1);
  /// - or a single param w/ an array: loc.set_orientation([0,0,1]);
  set_orientation : function(x,y,z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location' || x.constructor == THREE.Vector3){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    this.orientation_x = x;
    this.orientation_y = y;
    this.orientation_z = z;
    return this;
  },

  /// Return difference between location's orientation
  /// and specified one as expressed via an axis angle.
  orientation_difference : function(orx, ory, orz){
    if((typeof(orx) === "array" || typeof(orx) === "object") &&
       orx.length == 3 && !ory && !orz){
      ory = orx[1];
      orz = orx[2];
      orx = orx[0];
    }

    return Omega.Math.axis_angle(this.orientation_x,
                                 this.orientation_y,
                                 this.orientation_z,
                                 orx, ory, orz);
  },

  /// Return axis angle between location's orientation and specified coordinate
  rotation_to : function(x, y, z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location' || x.constructor == THREE.Vector3){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    var dx = x - this.x;
    var dy = y - this.y;
    var dz = z - this.z;
    if(dx == 0 && dy == 0 && dz == 0) return [NaN, NaN, NaN, NaN];

    return this.orientation_difference(Omega.Math.nrml(dx, dy, dz));
  },

  /// Boolean indicating if location is facing specified location
  facing : function(location, tolerance){
    var x,y,z;

    if((typeof(location) === "array" || typeof(location) === "object") && location.length == 3){
      x = location[0];
      y = location[1];
      z = location[2];

    }else if(location.json_class == 'Motel::Location' || location.constructor == THREE.Vector3){
      x = location.x;
      y = location.y;
      z = location.z;
    }

    var diff = this.rotation_to(x, y, z);
    return Math.abs(diff[0]) <= tolerance;
  },

  /* Convert orientation to short, human readable string
   */
  orientation_s : function(){
    return Omega.Math.round_to(this.orientation_x, 2) + "/" +
           Omega.Math.round_to(this.orientation_y, 2) + "/" +
           Omega.Math.round_to(this.orientation_z, 2);
  }
};
