/* Omega Star Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO solar flares

//= require "ui/canvas/entity/gfx"
//= require "omega/star/mesh"
//= require "omega/star/glow"
//= require "omega/star/light"

// Star Gfx Mixin

Omega.StarGfx = {
  async_gfx : 1,

  _load_meshes : function(event_cb){
    this._store_resource('mesh', new Omega.StarMesh({type : this.type, event_cb: event_cb}));
  },

  _load_glow : function(){
    this._store_resource('glow', new Omega.StarGlow());
  },

  _load_light : function(){
    this._store_resource('light', new Omega.StarLight());
  },

  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_meshes(event_cb);
    this._load_glow();
    this._load_light();
    this._loaded_gfx();
  },

  _init_mesh : function(){
    this.mesh = this._retrieve_resource('mesh').clone(); 
    this.mesh.omega_entity = this;
  },

  _init_glow : function(){
    this.glow = this._retrieve_resource('glow').clone();
    this.glow.tglow.position = this.mesh.tmesh.position;
    this.glow.set_color(this.type_int);
  },

  _init_light : function(){
    this.light = this._retrieve_resource('light').clone();
    this.light.position = this.mesh.tmesh.position;
    this.light.color.setHex(this.type_int);
  },

  _init_components : function(){
    this.components = [this.glow.tglow, this.mesh.tmesh, this.light];
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);
    this._init_mesh();
    this._init_glow();
    this._init_light();
    this._init_components();
    this._gfx_initialized = true;
  },

  /// For api compatability
  update_gfx : function(){}
};

$.extend(Omega.StarGfx, Omega.UI.CanvasEntityGfx);
