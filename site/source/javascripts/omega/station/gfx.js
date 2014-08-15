/* Omega Station Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"

//= require 'omega/station/mesh'
//= require 'omega/station/highlight'
//= require 'omega/station/lamps'
//= require 'omega/station/construction_bar'
//= require 'omega/station/construction_audio'

// Station GFX Mixin
Omega.StationGfx = {
  include_highlight : true,

  async_gfx : 2,

  _load_highlight : function(){
    this._store_resource('highlight', new Omega.StationHighlightEffects());
  },

  _load_construction_bar : function(){
    this._store_resource('construction_bar', new Omega.StationConstructionBar());
  },

  _load_mesh : function(event_cb){
    var material = new Omega.StationMeshMaterial({type : this.type, event_cb : event_cb});
    this._store_resource('mesh_material', material);

    var mesh_resource = 'station.' + this.type + '.mesh_geometry';
    var mesh_geometry = Omega.StationMesh.geometry_for(this.type);
    Omega.UI.AsyncResourceLoader.load(mesh_resource, mesh_geometry, event_cb);
  },

  _load_lamps : function(){
    var lamps = new Omega.StationLamps({type : this.type});
    this._store_resource('lamps', lamps);
  },

  _load_audio : function(){
    var audio = new Omega.StationConstructionAudioEffect();
    this._store_resource('construction_audio', audio);
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_highlight();
    this._load_construction_bar();
    this._load_lamps();
    this._load_audio();
    this._load_mesh(event_cb);
    this._loaded_gfx();
  },

  _init_components : function(){
    this.components = [this.position_tracker()];
  },

  _init_highlight : function(){
    this.highlight = this._retrieve_resource('highlight').clone();
    this.highlight.omega_entity = this;
    if(this.include_highlight) this.position_tracker().add(this.highlight.mesh);
  },

  _init_lamps : function(){
    this.lamps = this._retrieve_resource('lamps').clone();
    this.lamps.omega_entity = this;
    this.lamps.init_gfx();
  },

  _init_construction_bar : function(){
    this.construction_bar = this._retrieve_resource('construction_bar').clone();
    this.construction_bar.omega_entity = this;
    this.construction_bar.bar.init_gfx();
  },

  _init_audio : function(){
    this.construction_audio = this._retrieve_resource('construction_audio');
  },

  _add_lamp_components : function(){
    for(var l = 0; l < this.lamps.olamps.length; l++)
      this.mesh.tmesh.add(this.lamps.olamps[l].component);
  },

  _init_mesh : function(){
    var _this = this;
    var mesh_geometry = 'station.' + this.type + '.mesh_geometry';
    Omega.UI.AsyncResourceLoader.retrieve(mesh_geometry, function(geometry){
      var material = _this._retrieve_resource('mesh_material');
      var mesh = new Omega.ShipMesh({material: material.clone(),
                                     geometry: geometry.clone()});

      _this.mesh = mesh;
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this._add_lamp_components();
      _this.position_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this._gfx_initializing = false;
      _this._gfx_initialized  = true;
    });
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized() || this.gfx_initializing()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);
    this._init_components();
    this._init_highlight();
    this._init_lamps();
    this._init_construction_bar();
    this._init_audio();
    this._init_mesh();
    this.last_moved = new Date();
    this.update_gfx();
  },

  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);

    if(this.location.is_stopped()){
      if(this._has_orbit_line()) this._rm_orbit_line();
      this._run_movement_effects = this._run_movement;

    }else{
      if(!this._has_orbit_line()){
        this._calc_orbit();
        this._orbit_angle = this._current_orbit_angle();
        this._add_orbit_line(0x99CCEE);
      }

      if(this.mesh)
        this._run_movement_effects = this._run_orbit_movement;
    }
  },

  update_construction_gfx : function(){
    this.construction_bar.update();
  },

  _run_movement : function(){
  },

  _run_orbit_movement : function(){
    var now = new Date();
    var elapsed = now - this.last_moved;
    var dist = this.location.movement_strategy.speed * elapsed / 1000;

    this._orbit_angle += dist;
    this._set_orbit_angle(this._orbit_angle);
    this.last_moved = now;
    this.update_gfx();
  },

  run_effects : function(){
    if(this.lamps) this.lamps.run_effects();
    this._run_movement_effects();
  }
};

Omega.StationGfx._run_movement_effects = Omega.StationGfx._run_movement;

$.extend(Omega.StationGfx, Omega.StationConstructionGfxHelpers);
$.extend(Omega.StationGfx, Omega.UI.CanvasEntityGfx);
