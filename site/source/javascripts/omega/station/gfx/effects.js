/* Omega JS Station Graphics Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationGfxEffects = {
  _run_movement : function(){
  },

  _run_orbit_movement : function(){
    var now = new Date();
    var elapsed = now - this.last_moved;
    var dist = this.location.movement_strategy.speed * elapsed / 1000;

    this._orbit_angle += dist;
    this._set_orbit_angle(this._orbit_angle);
    this.last_moved = now;
    this.update_gfx();
  },

  run_effects : function(){
    if(this.lamps) this.lamps.run_effects();
    this._run_movement_effects();
  }
};

Omega.StationGfxEffects._run_movement_effects = Omega.StationGfxEffects._run_movement;
