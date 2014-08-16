/* Omega JS SolarSystem Graphics Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemGfxEffects = {
  // Run local system graphics effects
  run_effects : function(){
    this.interconns.run_effects();
    this.particles.run_effects();
  }
};
