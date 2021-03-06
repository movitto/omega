/* Omega JS Ship Linear Movement Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipLinearMovement = {
  _move_linear : function(elapsed){
    this.location.move_linear(elapsed);
  },

  _run_linear_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    this._rotate(elapsed);

    if(this.location.movement_strategy.dorientation)
      this.location.update_ms_dir();
    if(this.location.movement_strategy.dacceleration)
      this.location.update_ms_acceleration();

    this._move_linear(elapsed);

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  }
};
