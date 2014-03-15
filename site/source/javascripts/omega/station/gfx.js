/* Omega Station Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require 'omega/station/mesh'
//= require 'omega/station/highlight'
//= require 'omega/station/lamps'
//= require 'omega/station/construction_bar'
//= require 'omega/station/construction_audio'

// Station GFX Mixin
Omega.StationGfx = {
  async_gfx : 2,

  /// True/False if shared gfx are loaded
  gfx_loaded : function(){
    return typeof(Omega.Station.gfx) !== 'undefined' &&
           typeof(Omega.Station.gfx[this.type]) !== 'undefined';
  },

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;
    Omega.Station.gfx    = Omega.Station.gfx || {};

    var gfx              = {};
    gfx.highlight        = new Omega.StationHighlightEffects();
    gfx.construction_bar = new Omega.StationConstructionBar();
    gfx.mesh_material    = new Omega.StationMeshMaterial({config   : config,
                                                          type     : this.type,
                                                          event_cb : event_cb});
    gfx.lamps            =          new Omega.StationLamps({config : config,
                                                              type : this.type});
    gfx.construction_audio = new Omega.StationConstructionAudioEffect({config: config});
    Omega.Station.gfx[this.type] = gfx;

    Omega.StationMesh.load_template(config, this.type, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });
  },

  /// True / false if ship gfx have been initialized
  gfx_initialized : function(){
    return this.components.length > 0;
  },

  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    this.components = [];

    this.highlight = Omega.Station.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;

    this.lamps = Omega.Station.gfx[this.type].lamps.clone();
    this.lamps.omega_entity = this;
    this.lamps.init_gfx();

    this.construction_bar = Omega.Station.gfx[this.type].construction_bar.clone();
    this.construction_bar.omega_entity = this;
    this.construction_bar.bar.init_gfx(config, event_cb);

    this.construction_audio = Omega.Station.gfx[this.type].construction_audio;

    var _this = this;
    Omega.StationMesh.load(this.type, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.mesh.tmesh.add(_this.highlight.mesh);
      for(var l = 0; l < _this.lamps.olamps.length; l++)
        _this.mesh.tmesh.add(_this.lamps.olamps[l].component);
      _this.components.push(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
    });

    this.last_moved = new Date();
    this.update_gfx();
  },

  cp_gfx : function(from){
    /// return if not initialized
    if(!from.components || from.components.length == 0) return;
    this.components        = from.components;
    this.shader_components = from.shader_components;
    this.mesh              = from.mesh;
    this.highlight         = from.highlight;
    this.lamps             = from.lamps;
    this.construction_bar  = from.construction_bar;
    this.construction_audio = from.construction_audio;
  },

  update_gfx : function(){
    if(this.mesh) this.mesh.update();

    if(this.location.is_stopped()){
      if(this._has_orbit_line())
        this._rm_orbit_line();
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
    this.mesh.update();
  },

  run_effects : function(){
    this.lamps.run_effects();
    this._run_movement_effects();
  }
};

Omega.StationGfx._run_movement_effects = Omega.StationGfx._run_movement;

Omega.StationGfx =
  $.extend(Omega.StationGfx, Omega.StationConstructionGfxHelpers);
