/* Omega Location Tracking Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationTracking = {
  /// TODO need to clear tracking somewhere
  set_tracking : function(location){
    this.tracking = location;
  },

  /// Boolean indicating if location is near target
  near_target : function(dist){
    var target = this.tracking || this.movement_strategy.target;
    if(!target) return true;
    if(typeof(dist) === "undefined") dist = this.movement_strategy.distance;
    return this.distance_from(target) <= dist;
  },

  // Return distance from target
  distance_from_target : function(){
    var target = this.tracking || this.movement_strategy.target;
    return this.distance_from(target);
  },

  /// Return unit direction vector from this location's coords to specified coords
  direction_to_target : function(){
    var target = this.tracking || this.movement_strategy.target;
    return this.direction_to(target);
  },

  /// Return axis-angle rotation to target
  rotation_to_target : function(){
    var target = this.tracking || this.movement_strategy.target;
    return this.rotation_to(target);
  },

  /// Return angle component of axis-angle rotation to target
  angle_to_target : function(){
    return this.rotation_to_target()[0];
  },

  /// Boolean indicating if location is facing target
  facing_target : function(tolerance){
    return Math.abs(this.angle_to_target()) <= tolerance;
  }
};
