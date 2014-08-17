/* Omega JS Asteroid Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.AsteroidGfxLoader = {
  async_gfx : 1,

  _load_material : function(event_cb){
    this._store_resource('mesh_material', new Omega.AsteroidMeshMaterial({event_cb : event_cb}));
  },

  _load_geometries : function(event_cb){
    var resource = 'asteroid.meshes';
    var geometry_paths  = Omega.AsteroidMesh.geometry_paths();
    Omega.UI.AsyncResourceLoader.load(resource, geometry_paths, event_cb);
  },

  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_material(event_cb);
    this._load_geometries(event_cb);
    this._loaded_gfx();
  }
};
