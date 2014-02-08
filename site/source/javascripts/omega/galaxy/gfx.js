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

    gfx.density_wave1 = new Omega.GalaxyDensityWave(config, event_cb);
    gfx.density_wave2 = new Omega.GalaxyDensityWave(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.density_wave1 = Omega.Galaxy.gfx.density_wave1;//.clone(); // TODO
    this.density_wave2 = Omega.Galaxy.gfx.density_wave2;//.clone(); // TODO
    this.density_wave1.particles.mesh.rotation.set(1.57,0,0);
    this.density_wave2.particles.mesh.rotation.set(1.57,0,1.57);
    this.components = [this.density_wave1.particles.mesh,
                       this.density_wave2.particles.mesh];
    this.clock1 = new THREE.Clock();
    this.clock2 = new THREE.Clock();
  },

  run_effects : function(){
    this.density_wave1.particles.tick(this.clock1.getDelta());
    this.density_wave2.particles.tick(this.clock2.getDelta());
  }
};
