/* Omega JS Planet Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetGfxLoader = {
  async_gfx     : 1,

  _num_textures : 7, /// TODO: centralize  / make configurable

  _load_mesh : function(event_cb){
    this._store_resource('mesh', new Omega.PlanetMesh({type: this.type, event_cb: event_cb}));
  },

  _load_axis : function(){
    this._store_resource('axis', new Omega.PlanetAxis());
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_mesh(event_cb);
    this._load_axis();
    this._loaded_gfx();
  }
};
