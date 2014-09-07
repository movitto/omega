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
    if(!this.tracking) return true;
    if(typeof(dist) === "undefined") dist = this.movement_strategy.distance;
    return this.distance_from(this.tracking) <= dist;
  },

  // Return distance from target
  distance_from_target : function(){
    return this.distance_from(this.tracking.x,
                              this.tracking.y,
                              this.tracking.z);
  },

  /// Return unit direction vector from this location's coords to specified coords
  direction_to_target : function(){
    return this.direction_to(this.tracking.x,
                             this.tracking.y,
                             this.tracking.z);
  },

  /// Return axis-angle rotation to target
  rotation_to_target : function(){
    return this.rotation_to(this.tracking.x,
                            this.tracking.y,
                            this.tracking.z);
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
