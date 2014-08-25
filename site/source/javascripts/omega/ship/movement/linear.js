/* Omega JS Ship Linear Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipLinearMovement = {
  _run_linear_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    this._run_rotation_movement(page, elapsed);

    var dist = this.location.movement_strategy.speed * elapsed / 1000;
    this.location.move_linear(dist);

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
