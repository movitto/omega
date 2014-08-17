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
    return !!(this.movement_strategy) &&
      (this.movement_strategy.json_class == 'Motel::MovementStrategies::Stopped');
  },

  /// Boolean indicating if location if moving using specified ms type
  is_moving : function(ms_type){
    return !!(this.movement_strategy) &&
      this.movement_strategy.json_class ==
        Omega.MovementStrategies.json_classes[ms_type];
  }
};
