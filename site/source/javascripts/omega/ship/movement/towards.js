/* Omega JS Ship Towards Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTowardsMovement = {
  _near_dist : function(){
    var ms = this.location.movement_strategy;
    return Math.pow(ms.speed, 2) / (2 * ms.acceleration);
  },

  _run_towards_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var loc = this.location;
    var ms  = loc.movement_strategy;

    if(loc.arrived(ms.distance_tolerance)) return;

    /// always face target
    if(!loc.facing_target(ms.orientation_tolerance)) loc.face_target();
    this._rotate(elapsed);

    /// if near deaccelerate, else accelerate
    if(loc.near_target(this._near_dist())){
      loc.update_ms_acceleration({invert : true});
    }else{
      loc.update_ms_acceleration();
    }

    /// align movement
    if(loc.facing_movement(ms.orientation_tolerance)) loc.update_ms_dir();

    /// disable accel when rotating
    var orig_acceleration = ms.acceleration;
    if(!loc.rot_stopped())  ms.acceleration = 0;

    /// move toward target
    this._move_linear(elapsed);

    /// restore accel
    ms.acceleration = orig_acceleration;

    /// post-movement gfx opts
    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
