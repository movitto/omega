/* Omega Station Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO alot of the components used by station are duplicates
/// of those used by ship, should be consolidates into
/// common helpers

//= require 'omega/station/mesh'
//= require 'omega/station/highlight'
//= require 'omega/station/lamps'
//= require 'omega/station/construction_bar'

// Station GFX Mixin
Omega.StationGfx = {
  async_gfx : 2,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Station.gfx)            === 'undefined') Omega.Station.gfx = {};
    if(typeof(Omega.Station.gfx[this.type]) !== 'undefined') return;

    var gfx = {};
    Omega.Station.gfx[this.type] = gfx;
    gfx.mesh_material    = new Omega.StationMeshMaterial(config, this.type, event_cb);
    gfx.highlight        = new Omega.StationHighlightEffects();
    gfx.lamps            = new Omega.StationLamps(config, this.type);
    gfx.construction_bar = new Omega.StationConstructionBar();

    Omega.StationMesh.load_template(config, this.type, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.components = [];

    var _this = this;
    Omega.StationMesh.load(this.type, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.components.push(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
    });

    this.highlight = Omega.Station.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;
    this.components.push(this.highlight.mesh);

    this.lamps = Omega.Station.gfx[this.type].lamps.clone();
    this.lamps.omega_entity = this;
    for(var l = 0; l < this.lamps.olamps.length; l++){
      this.lamps.olamps[l].init_gfx();
      this.components.push(this.lamps.olamps[l].component);
    }

    this.construction_bar = Omega.Station.gfx[this.type].construction_bar.clone();
    this.construction_bar.omega_entity = this;
    this.construction_bar.bar.init_gfx(config, event_cb);
    this.update_gfx();
  },

  cp_gfx : function(from){
    /// return if not initialized
    if(!from.components || from.components.length == 0) return;
    to.components        = from.components;
    to.shader_components = from.shader_components;
    to.mesh              = from.mesh;
    to.highlight         = from.highlight;
    to.lamps             = from.lamps;
    to.construction_bar  = from.construction_bar;
  },

  update_gfx : function(){
    if(!this.location)        return;
    if(this.mesh)             this.mesh.update();
    if(this.highlight)        this.highlight.update();
    if(this.lamps)            this.lamps.update();
    if(this.construction_bar) this.construction_bar.update();
  },

  run_effects : function(){
    this.lamps.run_effects();
  },

  /// TODO move these to omega/station/construction_bar.js (helper module ?)
  _has_construction_bar : function(){
    return this.components.indexOf(this.construction_bar.bar.components[0]) != -1;
  },

  _add_construction_bar : function(){
    for(var c = 0; c < this.construction_bar.bar.components.length; c++)
      this.components.push(this.construction_bar.bar.components[c]);
  },

  _rm_construction_bar : function(){
    for(var c = 0; c < this.construction_bar.bar.components.length; c++){
      var i = this.components.indexOf(this.construction_bar.bar.components[c]);
      this.components.splice(i, 1);
    }
  }
};

