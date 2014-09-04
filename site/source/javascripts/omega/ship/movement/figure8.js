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

    var near_target   = loc.on_target();
    var facing_target = loc.facing_target(Math.PI / 64);
    if(!near_target && !loc.movement_strategy.rotating){
      loc.movement_strategy.rotating = true;
      loc.movement_strategy.inverted = !loc.movement_strategy.inverted;
    }

    if(loc.movement_strategy.rotating && !facing_target){
      loc.face_target();
      this._rotate(elapsed, loc.movement_strategy.inverted);

      if(loc.movement_strategy.inverted)
        loc.movement_strategy.inverted = false;

    }else{
      loc.movement_strategy.rotating = false;
    }

    loc.update_ms_acceleration();

    var should_scale =    loc.movement_strategy.rotating &&
                       !!(loc.movement_strategy.acceleration);
    if(should_scale) loc.scale_ms_acceleration();

    this._move_linear(elapsed);

    if(should_scale) loc.unscale_ms_acceleration();

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
