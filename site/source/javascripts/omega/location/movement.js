/* Omega Location Movement Operations
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationMovement = {
  /// Move location linearily by specified distance in
  /// direction of orientation
  //
  /// TODO stop at stop_distance if set
  move_linear : function(distance){
    if(this.movement_strategy.acceleration)
      this.accelerate();

    var dir = this.ms_dir();
    var dx = dir[0];
    var dy = dir[1];
    var dz = dir[2];

    this.x += distance * dx;
    this.y += distance * dy;
    this.z += distance * dz;
    this.distance_moved += distance;
  },

  accelerate : function(){
    var vdir = this.ms_dir();
    var dx = vdir[0];
    var dy = vdir[1];
    var dz = vdir[2];

    var adir = this.ms_acceleration();
    var ax = adir[0];
    var ay = adir[1];
    var az = adir[2];

    var speed        = this.movement_strategy.speed;
    var acceleration = this.movement_strategy.acceleration;

    var ndx = dx * speed + ax * acceleration;
    var ndy = dy * speed + ay * acceleration;
    var ndz = dz * speed + az * acceleration;

    var nspeed = Math.sqrt(Math.pow(ndx, 2) + Math.pow(ndy, 2) + Math.pow(ndz, 2));
    var max_speed = this.movement_strategy.max_speed;
    if(max_speed && nspeed > max_speed) nspeed = max_speed;

    this.movement_strategy.speed = nspeed;
    this.update_ms_dir(Omega.Math.nrml(ndx, ndy, ndz));
  },

  /// Rotate orientation by parameters in movement strategy
  rotate_orientation : function(angle){
    var stop      = this.movement_strategy.stop_angle;
    var projected = this.angle_rotated + angle;
    if(stop && projected > stop) return;
    this.angle_rotated += angle;

    var new_or = Omega.Math.rot(this.orientation_x,
                                this.orientation_y,
                                this.orientation_z,
                                angle,
                                this.movement_strategy.rot_x,
                                this.movement_strategy.rot_y,
                                this.movement_strategy.rot_z);

    this.orientation_x = new_or[0];
    this.orientation_y = new_or[1];
    this.orientation_z = new_or[2];
  },

  /// Update movement strategy so as to rotate towards target
  face_target : function(){
    var diff = this.orientation_difference(this.tracking.x,
                                           this.tracking.y,
                                           this.tracking.z);

    if(isNaN(diff[0]) || isNaN(diff[1])){
      this.movement_strategy.rot_x = 0;
      this.movement_strategy.rot_y = 0;
      this.movement_strategy.rot_z = 1;

    }else{
      this.movement_strategy.stop_angle = diff[0];
      this.movement_strategy.rot_x      = diff[1];
      this.movement_strategy.rot_y      = diff[2];
      this.movement_strategy.rot_z      = diff[3];
    }
  },

  face_away_from_target : function(){
    var diff = this.orientation_difference(this.tracking.x,
                                           this.tracking.y,
                                           this.tracking.z);

    if(isNaN(diff[0]) || isNaN(diff[1])){
      this.movement_strategy.rot_x = 0;
      this.movement_strategy.rot_y = 0;
      this.movement_strategy.rot_z = 1;

    }else{
      this.movement_strategy.stop_angle = Math.PI - diff[0];
      this.movement_strategy.rot_x      = diff[1];
      this.movement_strategy.rot_y      = diff[2];
      this.movement_strategy.rot_z      = diff[3];
    }
  }
};
