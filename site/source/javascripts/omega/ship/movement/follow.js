/* Omega JS Ship Follow Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipFollowMovement = {
  _run_follow_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var loc = this.location;
    var tracked = page.entity(loc.movement_strategy.tracked_location_id);
    loc.set_tracking(tracked.location);

    var within_distance = loc.on_target();
    var target_moving   = !!(tracked.location.movement_strategy.speed);
    var slower_target   = target_moving && (tracked.location.movement_strategy.speed < loc.movement_strategy.speed);
    var adjust_speed    = within_distance && slower_target;
    var facing_target   = loc.facing_target(Math.PI / 32);
    var facing_tangent  = loc.facing_target_tangent(Math.PI / 32);

    if(!within_distance || target_moving){
      if(!facing_target){
        loc.face_target();
        this._run_rotation_movement(page, elapsed);
      }

      var speed = adjust_speed ? tracked.location.movement_strategy.speed :
                                 loc.movement_strategy.speed;
      var dist  = speed * elapsed / 1000;
      loc.move_linear(dist);

    }else if(!target_moving){
      if(!facing_tangent) this._run_rotation_movement(page, elapsed, true);
      var dist  = loc.movement_strategy.speed * elapsed / 1000;
      loc.move_linear(dist);
    }

    /// TODO move into if block above
    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
