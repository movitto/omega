/* Omega JS Station Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationGfxLoader = {
  async_gfx : 2,

  _load_highlight : function(){
    this._store_resource('highlight', new Omega.StationHighlightEffects());
  },

  _load_construction_bar : function(){
    this._store_resource('construction_bar', new Omega.StationConstructionBar());
  },

  _load_mesh : function(event_cb){
    var material = new Omega.StationMeshMaterial({type : this.type, event_cb : event_cb});
    this._store_resource('mesh_material', material);

    var mesh_resource = 'station.' + this.type + '.mesh_geometry';
    var mesh_geometry = Omega.StationMesh.geometry_for(this.type);
    Omega.UI.AsyncResourceLoader.load(mesh_resource, mesh_geometry, event_cb);
  },

  _load_lamps : function(){
    var lamps = new Omega.StationLamps({type : this.type});
    this._store_resource('lamps', lamps);
  },

  _load_audio : function(){
    var audio = new Omega.StationConstructionAudioEffect();
    this._store_resource('construction_audio', audio);
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_highlight();
    this._load_construction_bar();
    this._load_lamps();
    this._load_audio();
    this._load_mesh(event_cb);
    this._loaded_gfx();
  }
};
