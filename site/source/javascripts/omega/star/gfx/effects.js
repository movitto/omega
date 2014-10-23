/* Omega JS Star Graphics Effects
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarGfxEffects = {
  run_effects : function(){
    var diff = (Date.now() - this.started) / 1000;
    this.surface.tmesh.material.uniforms.time.value = diff;
    this.halo.tmesh.material.uniforms.time.value = diff;
  }
};
