/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/density_wave"
//= require "omega/galaxy/center"

// Galaxy GFX Mixin
Omega.GalaxyGfx = {
  load_gfx : function(config, event_cb){
    if(typeof(Omega.Galaxy.gfx) !== 'undefined') return;
    var gfx = {};
    Omega.Galaxy.gfx = gfx;

    gfx.density_wave1 = new Omega.GalaxyDensityWave({config: config,
                                                     event_cb: event_cb});
    gfx.density_wave2 = new Omega.GalaxyDensityWave({config: config,
                                                     event_cb: event_cb});
    gfx.density_wave1.set_rotation(1.57,0,0);
    gfx.density_wave2.set_rotation(1.57,0,1.57);

    gfx.center = new Omega.GalaxyCenter()
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.density_wave1 = Omega.Galaxy.gfx.density_wave1;
    this.density_wave2 = Omega.Galaxy.gfx.density_wave2;
    this.center        = Omega.Galaxy.gfx.center;

    this.components = this.density_wave1.components().
               concat(this.density_wave2.components()).
               concat(this.center.components());
  },

  run_effects : function(){
    this.density_wave1.run_effects();
    this.density_wave2.run_effects();
  }
};
