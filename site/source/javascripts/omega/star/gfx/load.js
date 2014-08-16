/* Omega JS Star Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarGfxLoader = {
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

};
