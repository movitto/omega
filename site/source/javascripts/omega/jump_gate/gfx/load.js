/* Omega JS JumpGate Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateGfxLoader = {
  async_gfx : 3,

  _load_components : function(event_cb){
    this._store_resource('mesh_material',      new Omega.JumpGateMeshMaterial({event_cb: event_cb}));
    this._store_resource('lamp',               new Omega.JumpGateLamp());
    this._store_resource('particles',          new Omega.JumpGateParticles({event_cb: event_cb}));
    this._store_resource('selection_material', new Omega.JumpGateSelectionMaterial());
    this._store_resource('trigger_audio',      new Omega.JumpGateTriggerAudioEffect({}));
  },

  _load_geometry : function(event_cb){
    var geo_resource  = 'jump_gate.geometry';
    var mesh_geometry = Omega.JumpGateMesh.geometry();
    this._load_async_resource(geo_resource, mesh_geometry, event_cb);
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_components(event_cb);
    this._load_geometry(event_cb);
    this._loaded_gfx();
  }
};
