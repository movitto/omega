/* Omega Location Conversion Operations
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationConvert = {
  /// Return THREE.Vector3 instance w/ location's coordinates
  vector : function(){
    return new THREE.Vector3(this.x, this.y, this.z);
  },

  /// Update this locations attributes from another
  update : function(loc){
    this.x = loc.x;
    this.y = loc.y;
    this.z = loc.z;
    this.orientation_x = loc.orientation_x;
    this.orientation_y = loc.orientation_y;
    this.orientation_z = loc.orientation_z;
    this.parent_id = loc.parent_id;
    this.last_moved_at = loc.last_moved_at;
    this.angle_rotated = loc.angle_rotated;
    this.distance_moved = loc.distance_moved;
    this.update_ms(loc.movement_strategy);
  },

  /// Return rotation matrix generated from axis angle
  /// between location's orientation and base cartesion
  /// orientation we're using
  rotation_matrix : function(){
    var cart_x = Omega.Math.CARTESIAN_NORMAL[0];
    var cart_y = Omega.Math.CARTESIAN_NORMAL[1];
    var cart_z = Omega.Math.CARTESIAN_NORMAL[2];

    var axis = Omega.Math.cp(cart_x, cart_y, cart_z,
                             this.orientation_x,
                             this.orientation_y,
                             this.orientation_z);
    var angle = Omega.Math.abwn(cart_x, cart_y, cart_z,
                                this.orientation_x,
                                this.orientation_y,
                                this.orientation_z);
    if(!angle == 0) axis = Omega.Math.nrml(axis[0], axis[1], axis[2]);
    var matrix = new THREE.Matrix4().
                     makeRotationAxis({x: axis[0],
                                       y: axis[1],
                                       z: axis[2]}, angle);
    return matrix;
  }
};
