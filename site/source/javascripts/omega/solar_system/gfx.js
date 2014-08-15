/* Omega Solar System Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"
//= require "omega/solar_system/mesh"
//= require "omega/solar_system/text"
//= require "omega/solar_system/plane"
//= require "omega/solar_system/audio"
//= require "omega/solar_system/interconn"
//= require "omega/solar_system/particles"

// Solar System GFX Mixin
Omega.SolarSystemGfx = {
  async_gfx : 2,

  _load_mesh : function(){
    this._store_resource('mesh', new Omega.SolarSystemMesh());
  },

  _load_plane : function(event_cb){
    this._store_resource('plane', new Omega.SolarSystemPlane({event_cb: event_cb}));
  },

  _load_text : function(){
    this._store_resource('text_material', new Omega.SolarSystemTextMaterial());
  },

  _load_audio : function(){
    this._store_resource('hover_audio', new Omega.SolarSystemHoverAudioEffect());
    this._store_resource('click_audio', new Omega.SolarSystemClickAudioEffect());
  },

  _load_particles : function(event_cb){
    this._store_resource('particles',  new Omega.SolarSystemParticles({event_cb : event_cb}));
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_mesh();
    this._load_plane(event_cb);
    this._load_text();
    this._load_audio();
    this._load_particles(event_cb);
    this._loaded_gfx();
  },

  _init_mesh : function(){
    this.mesh = this._retrieve_resource('mesh').clone();
    this.mesh.omega_entity = this;
  },

  _init_plane : function(){
    this.plane = this._retrieve_resource('plane').clone();
    this.plane.omega_entity = this;
  },

  _init_text : function(){
    var material = this._retrieve_resource('text_material').material;
    this.text = new Omega.SolarSystemText({text: this.title(), material: material})
    this.text.omega_entity = this;
  },

  _init_audio : function(){
    this.hover_audio = this._retrieve_resource('hover_audio');
    this.click_audio = this._retrieve_resource('click_audio');
  },

  _init_particles : function(){
    this.particles = this._retrieve_resource('particles').clone();
    this.particles.omega_entity = this;
  },

  _init_interconns : function(){
    this.interconns.init_gfx(event_cb);
  },

  _init_components : function(){
    this.position_tracker().add(this.plane.tmesh);
    this.position_tracker().add(this.text.text);

    this.components = [this.position_tracker()].
                        concat(this.interconns.components()).
                        concat(this.particles.components());

  },

  // Initialize local system graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);

    this._init_mesh();
    this._init_plane();
    this._init_text();
    this._init_audio();
    this._init_particles();
    this._init_interconns(event_cb);
    this._init_components();

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

$.extend(Omega.SolarSystemGfx, Omega.UI.CanvasEntityGfx);
