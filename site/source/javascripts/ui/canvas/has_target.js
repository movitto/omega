/* Omega JS Canvas Has Target Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.HasTarget = function(){};

/// Subclasses should implement
/// - target defining target
Omega.UI.HasTarget.prototype = {
  disable_target_update : function(){
    this._update_target_loc = function(){}
  },

  enable_target_update : function(){
    this._update_target_loc = function(){
      if(this.target_loc_needs_update())
        this.update_target_loc();
    };
  },

  update : function(){
    this._update_target_loc();
  },

  update_state : function(){
    if(this.has_target()){
      this.enable();
      this.enable_target_update();
      this.update();

    }else{
      this.disable();
      this.disable_target_update();
    }
  },

  target_loc : function(new_loc){
    if(new_loc) this._target_loc = new_loc.clone();
    return this._target_loc;
  },

  has_target : function(){
    return !!(this.target());
  },

  has_target_loc : function(){
    return !!(this.target_loc());
  },

  target_loc_needs_update : function(){
    var tolerance = 5; // TODO configurable ?
    var target = this.target();
    var tl     = this.target_loc();
    if(!this.has_target_loc()) return true;

    var different_target  = target.location.id != tl.id;
    var exceeds_tolerance = (target.location.distance_from(tl.x, tl.y, tl.z) > tolerance);
    return different_target || exceeds_tolerance;
  },

  get_distance : function(){
    var target_loc = this.target_loc();
    var loc        = this.omega_entity.scene_location();
    return loc.distance_from(target_loc.x, target_loc.y, target_loc.z);
  },

  get_direction : function(){
    var target_loc = this.target_loc();
    var loc        = this.omega_entity.scene_location();
    var dist       = loc.distance_from(target_loc.x, target_loc.y, target_loc.z);
    var dx         = (target_loc.x - loc.x) / dist;
    var dy         = (target_loc.y - loc.y) / dist;
    var dz         = (target_loc.z - loc.z) / dist;
    return [dx, dy, dz];
  }
};
