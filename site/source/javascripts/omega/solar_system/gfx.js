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

  load_gfx : function(config, event_cb){
    if(typeof(Omega.SolarSystem.gfx) !== 'undefined') return;
    var gfx = {};
    gfx.mesh               = new Omega.SolarSystemMesh();
    gfx.plane              = new Omega.SolarSystemPlane(config, event_cb);
    gfx.text_material      = new Omega.SolarSystemTextMaterial();
    gfx.interconn_material = new Omega.SolarSystemInterconnMaterial(); 
    gfx.interconn_particle_material =
      new Omega.SolarSystemInterconnParticleMaterial(config, event_cb);
    Omega.SolarSystem.gfx = gfx;
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.mesh = Omega.SolarSystem.gfx.mesh.clone();
    this.mesh.omega_entity = this;
  
    this.plane = Omega.SolarSystem.gfx.plane.clone();
    this.plane.omega_entity = this;

    /// text geometry needs to be created on system by system basis
    this.text = new Omega.SolarSystemText(this.title())
    this.text.omega_entity = this;
  
    this.components = [this.plane.tmesh, this.text.text];
  
    this.unqueue_interconns();

    this.update_gfx();
  },

  update_gfx : function(){
    if(!this.location) return;
    if(this.mesh)  this.mesh.update();
    if(this.plane) this.plane.update();
    if(this.text)  this.text.update();
  },

  run_effects : function(){
    this._interconn_effects();
  }
};
