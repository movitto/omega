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
  include_highlight : true,

  async_gfx : 2,

  // Returns location which to render gfx components, overridable
  scene_location : function(){
    return this.location;
  },

  // Returns 3D object tracking station position
  position_tracker : function(){
    if(!this._position_tracker)
      this._position_tracker = new THREE.Object3D();
    return this._position_tracker;
  },

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

  /// True / false if station gfx are being initialized
  gfx_initializing : function(){
    return !this.gfx_initialized() &&
            this.components.indexOf(this.position_tracker()) != -1;
  },

  /// True / false if station gfx have been initialized
  gfx_initialized : function(){
    return !!(this._gfx_initialized);
  },

  init_gfx : function(config, event_cb){
    if(this.gfx_initialized() || this.gfx_initializing()) return;
    this.load_gfx(config, event_cb);
    this.components = [];

    this.components.push(this.position_tracker());

    this.highlight = Omega.Station.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;
    if(this.include_highlight)
      this.position_tracker().add(this.highlight.mesh);

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

      for(var l = 0; l < _this.lamps.olamps.length; l++)
        _this.mesh.tmesh.add(_this.lamps.olamps[l].component);

      _this.position_tracker().add(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
      _this._gfx_initialized = true;
    });

    this.last_moved = new Date();
    this.update_gfx();
  },

  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);

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
    this.update_gfx();
  },

  run_effects : function(){
    if(this.lamps) this.lamps.run_effects();
    this._run_movement_effects();
  }
};

Omega.StationGfx._run_movement_effects = Omega.StationGfx._run_movement;

Omega.StationGfx =
  $.extend(Omega.StationGfx, Omega.StationConstructionGfxHelpers);
