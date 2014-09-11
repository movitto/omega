/* Omega JS Planet Graphics Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetGfxEffects = {
  /// Run local system graphics effects
  run_effects : function(){
    var ms   = this.location.movement_strategy;
    var curr = new Date();
    var elapsed = (curr - this.last_moved) / 1000;

    // update orbit angle
    this._orbit_angle += ms.speed * elapsed;
    this.location.set(this._coords_from_orbit_angle(this._orbit_angle));

    // spin the planet
    this.mesh.spin(elapsed / 2 * this.spin_scale);

    this.update_gfx();
    this.last_moved = curr;
  }
};
