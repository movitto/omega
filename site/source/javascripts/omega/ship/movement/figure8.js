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

    /// TODO set / leverage inverted flags
    var near_target   = loc.on_target();
    var facing_target = loc.facing_target(Math.PI / 64);
    if(!near_target && !this.rotating)
      this.rotating = true;
    if(this.rotating && !facing_target){
      loc.face_target();
      this._run_rotation_movement(page, elapsed);
    }else{
      this.rotating = false;
    }

    var speed = this.rotating ? loc.movement_strategy.speed / 2 :
                                loc.movement_strategy.speed;
    var dist = speed * elapsed / 1000;
    loc.move_linear(dist);

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
