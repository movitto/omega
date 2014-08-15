/* Omega Jump Gate Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"
//= require 'omega/jump_gate/mesh'
//= require 'omega/jump_gate/lamp'
//= require 'omega/jump_gate/particles'
//= require 'omega/jump_gate/selection'
//= require 'omega/jump_gate/trigger_audio'

// JumpGate GFX Mixin
Omega.JumpGateGfx = {
  async_gfx : 3,

  _load_components : function(event_cb){
    this._store_resource('mesh_material',      new Omega.JumpGateMeshMaterial({event_cb: event_cb}));
    this._store_resource('lamp',               new Omega.JumpGateLamp());
    this._store_resource('particles',          new Omega.JumpGateParticles({event_cb: event_cb}));
    this._store_resource('selection_material', new Omega.JumpGateSelectionMaterial());
    this._store_resource('trigger_audio',      new Omega.JumpGateTriggerAudioEffect({}));
  },

  _load_geometry : function(event_cb){
    var geo_resource  = 'jump_gate.geometry';
    var mesh_geometry = Omega.JumpGateMesh.geometry();
    Omega.UI.AsyncResourceLoader.load(geo_resource, mesh_geometry, event_cb);
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_components(event_cb);
    this._load_geometry(event_cb);
    this._loaded_gfx();
  },

  _init_components : function(){
    this.components = [this.position_tracker()];
  },

  _init_lamps : function(){
    this.lamp = this._retrieve_resource('lamp').clone();
    this.lamp.omega_entity = this;
    this.lamp.olamp.init_gfx();
  },

  _init_particles : function(){
    this.particles = this._retrieve_resource('particles').clone();
    this.particles.omega_entity = this;
    this.components.push(this.particles.particles.mesh);
  },

  _init_selection : function(){
    var material = this._retrieve_resource('selection_material').material;
    this.selection = Omega.JumpGateSelection.for_jg(this, material);
    this.selection.omega_entity = this;
  },

  _init_audio : function(){
    this.trigger_audio = this._retrieve_resource('trigger_audio');
  },

  _init_mesh : function(){
    var _this = this;
    Omega.UI.AsyncResourceLoader.retrieve('jump_gate.geometry', function(geometry){
      var material = _this._retrieve_resource('mesh_material').material;
      var mesh     = new Omega.JumpGateMesh({geometry : geometry,
                                             material : material});
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.mesh.tmesh.add(_this.lamp.olamp.component);
      _this.position_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this._gfx_initialized = true;
    });
  },

  // Intiialize local jump gate graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);
    this._init_components();
    this._init_lamps();
    this._init_particles();
    this._init_selection();
    this._init_audio();
    this._init_mesh();
    this.update_gfx();
  },

  // Run local jump gate graphics effects
  run_effects : function(){
    this.lamp.run_effects();
    this.particles.run_effects();
    this.mesh.run_effects();
  },

  update_gfx : function(){
    if(!this.scene_location()) return;

    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);

    if(this.particles) this.particles.update();
  }
}

$.extend(Omega.JumpGateGfx, Omega.UI.CanvasEntityGfx);
