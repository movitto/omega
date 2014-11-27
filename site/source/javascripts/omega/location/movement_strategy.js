/* Omega Location MovementStrategy Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationMovementStrategy = {
  /// Return clone of this location
  clone : function(){
     var cloned = new Omega.Location();
     return $.extend(true, cloned, this); /// deep copy
  },

  /// Alias for movement_strategy
  ms : function(){ return this.movement_strategy; },

  /// Special case to update movement strategy since ms doesn't
  /// currently have it's own JS class heirarchy
  update_ms : function(ms){
    if(ms != null){
      this.movement_strategy = ms;
    }

    // XXX currently no js obj for movement strategy
    if(this.movement_strategy && this.movement_strategy.data){
      $.extend(this.movement_strategy, this.movement_strategy.data);
      delete this.movement_strategy['data'];
    }
  },

  /// Boolean indicating if location is not moving
  is_stopped : function(){
    return !this.movement_strategy ||
      (this.movement_strategy.json_class == 'Motel::MovementStrategies::Stopped');
  },

  /// Boolean indicating if location if moving using specified ms type
  is_moving : function(ms_type){
    return !!(this.movement_strategy) &&
      this.movement_strategy.json_class ==
        Omega.MovementStrategies.json_classes[ms_type];
  },

  /// Return movement strategy direction
  ms_dir : function(){
    return [this.movement_strategy.dx,
            this.movement_strategy.dy,
            this.movement_strategy.dz];
  },

  /// Return movement strategy acceleration axis
  ms_acceleration : function(){
    return [this.movement_strategy.ax,
            this.movement_strategy.ay,
            this.movement_strategy.az];
  },

  /// Update movement strategy direction from specified dir or location orientation
  update_ms_dir : function(dir){
    if(!dir) dir = [this.orientation_x,
                    this.orientation_y,
                    this.orientation_z];

    this.movement_strategy.dx = dir[0];
    this.movement_strategy.dy = dir[1];
    this.movement_strategy.dz = dir[2];
  },

  /// Update movement strategy acceleration from location orientation
  update_ms_acceleration : function(dir){
    if(!dir) dir = [this.orientation_x,
                    this.orientation_y,
                    this.orientation_z];

    this.movement_strategy.ax = dir[0];
    this.movement_strategy.ay = dir[1];
    this.movement_strategy.az = dir[2];
  },

  facing_movement : function(tolerance){
    return this.orientation_difference(this.ms_dir())[0] <= tolerance;
  }
};
