/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/density_wave"

// Galaxy GFX Mixin
Omega.GalaxyGfx = {
  load_gfx : function(config, event_cb){
    if(typeof(Omega.Galaxy.gfx) !== 'undefined') return;
    var gfx = {};
    Omega.Galaxy.gfx = gfx;

    gfx.density_wave1 = new Omega.GalaxyDensityWave({config   : config,
                                                     event_cb : event_cb,
                                                     type     : 'stars'});
    gfx.density_wave2 = new Omega.GalaxyDensityWave({config   : config,
                                                     event_cb : event_cb,
                                                     type     : 'clouds',
                                                     colorStart : 0x3399FF,
                                                     colorEnd : 0x33FFC2});
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.density_wave1 = Omega.Galaxy.gfx.density_wave1;
    this.density_wave2 = Omega.Galaxy.gfx.density_wave2;

    /// order of components here affects rendering
    this.components = this.density_wave2.components().
               concat(this.density_wave1.components());
  },

  run_effects : function(){
    this.density_wave1.run_effects();
    this.density_wave2.run_effects();
  }
};
