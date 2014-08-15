/* Omega Galaxy Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"
//= require "omega/galaxy/density_wave"

// Galaxy GFX Mixin
Omega.GalaxyGfx = {
  _stars : function(event_cb){
    return new Omega.GalaxyDensityWave({event_cb   : event_cb,
                                        type       : 'stars'});
  },

  _clouds : function(event_cb){
    return new Omega.GalaxyDensityWave({event_cb   : event_cb,
                                        type       : 'clouds',
                                        colorStart : 0x3399FF,
                                        colorEnd   : 0x33FFC2});

  },

  _load_components : function(event_cb){
    this._store_resource('stars', this._stars(event_cb));
    this._store_resource('clouds', this._clouds(event_cb));
  },

  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_components(event_cb);
    this._loaded_gfx();
  },

  _init_components : function(){
    this.stars  = this._retrieve_resource('stars');
    this.clouds = this._retrieve_resource('clouds');

    /// order of components here affects rendering
    this.components = this.clouds.components().
               concat(this.stars.components());
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);

    this._init_components();

    this._gfx_initializing = false;
    this._gfx_initialized  = true;
  },

  run_effects : function(){
    this.stars.run_effects();
    this.clouds.run_effects();
  }
};

$.extend(Omega.GalaxyGfx, Omega.UI.CanvasEntityGfx);
