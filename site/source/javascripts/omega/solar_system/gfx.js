/* Omega Solar System Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx"
//= require "omega/solar_system/mesh"
//= require "omega/solar_system/text"
//= require "omega/solar_system/plane"
//= require "omega/solar_system/audio"
//= require "omega/solar_system/interconn"
//= require "omega/solar_system/particles"

// Solar System GFX Mixin
Omega.SolarSystemGfx = {
  async_gfx : 2,

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;

    var gfx = {};
    gfx.mesh              = new Omega.SolarSystemMesh();
    gfx.plane             = new Omega.SolarSystemPlane({config:   config,
                                                        event_cb: event_cb});
    gfx.text_material     = new Omega.SolarSystemTextMaterial();
    gfx.audio_effects     = new Omega.SolarSystemAudioEffects({config: config});
    gfx.particles         = new Omega.SolarSystemParticles({config : config,
                                                            event_cb : event_cb});
    Omega.SolarSystem.gfx = gfx;
    this._loaded_gfx();
  },

  // Initialize local system graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    this.mesh = Omega.SolarSystem.gfx.mesh.clone();
    this.mesh.omega_entity = this;
  
    this.plane = Omega.SolarSystem.gfx.plane.clone();
    this.plane.omega_entity = this;

    this.text = new Omega.SolarSystemText(this.title())
    this.text.omega_entity = this;

    this.audio_effects = Omega.SolarSystem.gfx.audio_effects;

    this.particles = Omega.SolarSystem.gfx.particles.clone(config, event_cb);
    this.particles.omega_entity = this;

    this.interconns.init_gfx(config, event_cb);

    this.position_tracker().add(this.plane.tmesh);
    this.position_tracker().add(this.text.text);

    this.components = [this.position_tracker()].
                        concat(this.interconns.components()).
                        concat(this.particles.components());

    this._gfx_initialized = true;
    this.interconns.unqueue();
    this.update_gfx();
  },

  // Update local system graphics on core entity changes
  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);

    this.particles.update();
    this.interconns.update();
  },

  // Run local system graphics effects
  run_effects : function(){
    this.interconns.run_effects();
    this.particles.run_effects();
  }
};

$.extend(Omega.SolarSystemGfx, Omega.EntityGfx);
