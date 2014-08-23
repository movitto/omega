/* Omega JS SolarSystem Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemGfxLoader = {
  /// plane texture, particles, interconn particles
  async_gfx : 3,

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
  }
};
