/* Omega Solar System Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/solar_system/mesh"
//= require "omega/solar_system/plane"
//= require "omega/solar_system/text"
//= require "omega/solar_system/interconn"

// Solar System GFX Mixin
Omega.SolarSystemGfx = {
  async_gfx : 2,

  // True/False if shared gfx are loaded
  gfx_loaded : function(){
    return typeof(Omega.SolarSystem.gfx) !== 'undefined';
  },

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;

    var gfx = {};
    gfx.mesh              = new Omega.SolarSystemMesh();
    gfx.plane             = new Omega.SolarSystemPlane({config:   config,
                                                        event_cb: event_cb});
    gfx.text_material     = new Omega.SolarSystemTextMaterial();
    Omega.SolarSystem.gfx = gfx;
  },

  // True / false if local system gfx have been initialized
  gfx_initialized : function(){
    return this.components.length > 0;
  },

  // Intiialize local system graphc
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    this.mesh = Omega.SolarSystem.gfx.mesh.clone();
    this.mesh.omega_entity = this;
  
    this.plane = Omega.SolarSystem.gfx.plane.clone();
    this.plane.omega_entity = this;

    /// text geometry needs to be created on system by system basis
    this.text = new Omega.SolarSystemText(this.title())
    this.text.omega_entity = this;

    /// interconnects pre-created on system by system basis, init gfx here
    this.interconns.init_gfx(config, event_cb);
  
    this.components = [this.plane.tmesh, this.text.text, this.interconns.particles.mesh];
  
    this.interconns.unqueue();
    this.update_gfx();
  },

  // Update local system graphics on core entity changes
  update_gfx : function(){
    if(!this.location) return;
    if(this.mesh)  this.mesh.update();
    if(this.plane) this.plane.update();
    if(this.text)  this.text.update();
  },

  // Run local system graphics effects
  run_effects : function(){
    this.interconns.run_effects();
  }
};
