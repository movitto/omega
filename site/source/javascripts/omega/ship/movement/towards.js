/* Omega JS Ship Towards Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTowardsMovement = {
  _towards_rotational_time : function(){
    return Math.PI / Math.abs(this.location.movement_strategy.rot_theta);
  },

  _towards_rotational_distance : function(){
    return this._towards_rotational_time() * this.location.movement_strategy.speed;
  },

  _towards_linear_time : function(){
    return this.location.movement_strategy.speed / this.location.movement_strategy.acceleration;
  },

  _towards_linear_distance : function(){
    var lt = this._towards_linear_time();
    var ms = this.location.movement_strategy;
    return ms.speed * lt - ms.acceleration / 2 * (Math.pow(lt, 2));
  },

  _near_dist : function(){
    return this._towards_linear_distance() + this._towards_rotational_distance();
  },

  _run_towards_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var loc = this.location;

    if(loc.movement_strategy.arriving || loc.near_target(this._near_dist())){
console.log('near ' + loc.movement_strategy.target + " " + this._near_dist())
      if(!loc.movement_strategy.arriving)
        loc.face(-loc.movement_strategy.dx,
                 -loc.movement_strategy.dy,
                 -loc.movement_strategy.dz);
      this._rotate(elapsed);
      loc.movement_strategy.arriving = true;

    }else{
console.log('far ' + loc.angle_rotated);
      loc.face_target();
      this._rotate(elapsed);
      loc.movement_strategy.arriving = false;

      if(loc.facing_movement(loc.movement_strategy.orientation_tolerance))
        loc.update_ms_dir();
    }

    var orig_acceleration = loc.movement_strategy.acceleration;
    if(!loc.rot_stopped()) loc.movement_strategy.acceleration = 0;

    loc.update_ms_acceleration();
    this._move_linear(elapsed);

    if(loc.near_target(loc.movement_strategy.distance_tolerance))
      loc.set(loc.movement_strategy.target);

    loc.movement_strategy.acceleration = orig_acceleration;

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
