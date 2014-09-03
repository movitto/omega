/* Omega JS Ship Rotation Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipRotationMovement = {
  _rotate : function(elapsed, invert){
    var rot_theta = invert ? (this.location.movement_strategy.rot_theta * -1) :
                              this.location.movement_strategy.rot_theta
    if(!rot_theta) return;

    var stop_angle = this.location.movement_strategy.stop_angle;
    if(this.location.angle_rotated + rot_theta > stop_angle)
      rot_theta = stop_angle - this.location.angle_rotated;

    var dist = rot_theta * elapsed / 1000;
    this.location.rotate_orientation(dist);
    this.location.angle_rotated += rot_theta;
  },

  _run_rotation_movement : function(page, elapsed, invert){
    var now     = new Date();
        elapsed = elapsed || (now - this.last_moved);

    this._rotate(elapsed, invert);

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
