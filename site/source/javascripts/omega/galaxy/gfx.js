/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/density_wave"

// Galaxy GFX Mixin
Omega.GalaxyGfx = {
  load_gfx : function(config, event_cb){
    if(typeof(Omega.Galaxy.gfx) !== 'undefined') return;
    var gfx = {};
    Omega.Galaxy.gfx = gfx;

    gfx.density_wave = new Omega.GalaxyDensityWave(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.density_wave = Omega.Galaxy.gfx.density_wave;//.clone(); // TODO
    this.density_wave.particles.mesh.rotation.set(1.57,0,0);
    this.components = [this.density_wave.particles.mesh];
    this.clock = new THREE.Clock();
  },

  run_effects : function(){
    this.density_wave.particles.tick(this.clock.getDelta());
  }
};
