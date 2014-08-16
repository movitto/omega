/* Omega JS JumpGate Graphics Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateGfxEffects = {
  // Run local jump gate graphics effects
  run_effects : function(){
    this.lamp.run_effects();
    this.particles.run_effects();
    this.mesh.run_effects();
  }
};
