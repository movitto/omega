/* Omega JS Ship Follow Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipFollowMovement = {
  _orbit_set : function(){
    return this.__orbit_initialized;
  },

  _init_orbit : function(){
    this.__orbit_initialized = true;
    var ms = this.location.movement_strategy;

    ms.e = 0;
    ms.p = ms.distance;

    var primary   = Omega.Math.CARTESIAN_MAJOR;
    var secondary = Omega.Math.CARTESIAN_NORMAL;
    ms.dmajx      =  primary[0];
    ms.dmajy      =  primary[1];
    ms.dmajz      =  primary[2];
    ms.dminx      =  secondary[0];
    ms.dminy      =  secondary[1];
    ms.dminz      = -secondary[2];

    this._calc_orbit();
  },

  _run_follow_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var loc = this.location;
    var tracked = page.entity(loc.movement_strategy.tracked_location_id);
    loc.set_tracking(tracked.location);

    var within_distance = loc.near_target();
    var target_moving   = !!(tracked.location.movement_strategy.speed);

    if(!this._orbit_set()) this._init_orbit();

    if(target_moving){
      var slower_target = (tracked.location.movement_strategy.speed < loc.movement_strategy.speed);
      var reduce_speed  = within_distance && slower_target;
      var orig_speed    = loc.movement_strategy.speed;

      if(!loc.facing_target(Math.PI / 32)){
        loc.face_target();
        this._rotate(elapsed);
        loc.update_ms_acceleration();
      }

      if(reduce_speed) loc.movement_strategy.speed = tracked.location.movement_strategy.speed;

      this._move_linear(elapsed);

      if(reduce_speed) loc.movement_strategy.speed = orig_speed;

    }else{
      var nxt = Math.PI/6;

      var current = this._orbit_angle_from_coords(loc.coordinates());
      var target  = this._coords_from_orbit_angle(current + nxt);

      loc.face(target);
      this._rotate(elapsed);
      loc.update_ms_acceleration();

      this._move_linear(elapsed);
    }

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};

$.extend(Omega.ShipFollowMovement, Omega.OrbitHelpers);

Omega.ShipFollowMovement._orbit_center = function(){
  return this.location.tracking.coordinates();
};
