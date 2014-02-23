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

    this.density_wave1 = Omega.Galaxy.gfx.density_wave1;
    this.density_wave2 = Omega.Galaxy.gfx.density_wave2;

    this.density_wave1.stars.mesh.rotation.set(1.57,0,0);
    this.density_wave2.stars.mesh.rotation.set(1.57,0,1.57);
    this.density_wave1.clouds.mesh.rotation.set(1.57,0,0);
    this.density_wave2.clouds.mesh.rotation.set(1.57,0,1.57);

    this.components = [this.density_wave1.stars.mesh,
                       this.density_wave2.stars.mesh,
                       this.density_wave1.clouds.mesh,
                       this.density_wave2.clouds.mesh];

    this.clock = new THREE.Clock();
  },

  run_effects : function(){
    var delta = this.clock.getDelta();
    this.density_wave1.stars.tick(delta);
    this.density_wave2.stars.tick(delta);
    this.density_wave1.clouds.tick(delta);
    this.density_wave2.clouds.tick(delta);
  }
};
