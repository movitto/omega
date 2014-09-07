/* Omega JS Ship Figure8 Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipFigure8Movement = {
  _run_figure8_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var loc = this.location;
    var tracked = page.entity(loc.movement_strategy.tracked_location_id);
    loc.set_tracking(tracked.location);

    var within_distance = loc.near_target();
    var near_target     = loc.near_target(loc.movement_strategy.distance / 5);
    var facing_target   = loc.facing_target(Math.PI / 64);

    if(!within_distance){
      if(loc.movement_strategy.evading) loc.face_target();
      loc.movement_strategy.evading = false;
    }else{
      if(near_target){
        if(!loc.movement_strategy.evading) loc.face_away_from_target();
        loc.movement_strategy.evading = true;
      }

      if(!loc.movement_strategy.evading && !facing_target) loc.face_target();
    }

    this._rotate(elapsed);
    loc.update_ms_acceleration();

    var pause_acceleration = (!within_distance && !facing_target);
    var orig_acceleration  = loc.movement_strategy.acceleration;
    if(pause_acceleration) loc.movement_strategy.acceleration = 0;

    this._move_linear(elapsed);

    if(pause_acceleration) loc.movement_strategy.acceleration = orig_acceleration;

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
