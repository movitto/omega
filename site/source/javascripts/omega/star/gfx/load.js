/* Omega JS Star Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarGfxLoader = {
  async_gfx : 1,

  _color : function(){
    var r = parseInt(this.type.substring(0,2), 16) / 255.0;
    var g = parseInt(this.type.substring(2,4), 16) / 255.0;
    var b = parseInt(this.type.substring(4,6), 16) / 255.0;
    return new THREE.Vector4(r, g, b, 1.0);
  },

  _load_meshes : function(event_cb){
    this._store_resource('mesh', new Omega.StarMesh({type : this.type, event_cb: event_cb}));
  },

  _load_glow : function(){
    this._store_resource('glow', new Omega.StarGlow());
  },

  _load_surface : function(color, event_cb){
    this._store_resource('surface', new Omega.StarSurface({color : color, event_cb : event_cb}));
  },

  _load_halo : function(color, event_cb){
    this._store_resource('halo', new Omega.StarHalo({color : color, event_cb : event_cb}));
  },

  _load_light : function(){
    this._store_resource('light', new Omega.StarLight());
  },

  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_meshes(event_cb);
    this._load_glow();

    var color = this._color();
    this._load_surface(color, event_cb);
    this._load_halo(color, event_cb);

    this._load_light();
    this._loaded_gfx();
  },

};
