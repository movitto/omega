/* Omega JS Ship Graphics Loader
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/attack/shell"
//= require "omega/ship/attack/missile"

Omega.ShipGfxLoader = {
  /// geometry, missile geometry
  async_gfx : 2,

  _load_textures : function(event_cb){
    this._store_resource('mesh_material',     new Omega.ShipMeshMaterial({type: this.type, event_cb : event_cb}));
  },

  _load_artillery : function(event_cb){
    var material = new Omega.ShipShellMaterial({event_cb : event_cb}).material;
    var template = Omega.ShipShell.template({material : material});
    this._store_resource('artillery',         new Omega.ShipArtillery({template : template}));
  },

  _load_components : function(event_cb){
    this._store_resource('hp_bar',            new Omega.ShipHpBar());
    this._store_resource('highlight',         new Omega.ShipHighlightEffects());
    this._store_resource('lamps',             new Omega.ShipLamps({type: this.type}));
    this._store_resource('trails',            new Omega.ShipTrails({type: this.type}));
    this._store_resource('visited_route',     new Omega.ShipVisitedRoute());
    this._store_resource('attack_vector',     new Omega.ShipAttackVector());
    this._store_resource('mining_vector',     new Omega.ShipMiningVector());
    this._store_resource('trajectory1',       new Omega.ShipTrajectory({color: 0x0000FF, direction: 'primary'}));
    this._store_resource('trajectory2',       new Omega.ShipTrajectory({color: 0x00FF00, direction: 'secondary'}));
    this._load_artillery(event_cb);
  },

  _load_effects : function(){
    this._store_resource('destruction',       new Omega.ShipDestructionEffect());
    this._store_resource('explosions',        new Omega.ShipExplosionEffect());
    this._store_resource('smoke',             new Omega.ShipSmokeEffect());
  },

  _load_audio : function(){
    this._store_resource('docking_audio',     new Omega.ShipDockingAudioEffect());
    this._store_resource('mining_audio',      new Omega.ShipMiningAudioEffect());
    this._store_resource('destruction_audio', new Omega.ShipDestructionAudioEffect());
    this._store_resource('mining_completed',  new Omega.ShipMiningCompletedAudioEffect());
    this._store_resource('combat_audio',      new Omega.ShipCombatAudioEffect());
    this._store_resource('movement_audio',    new Omega.ShipMovementAudioEffect());
  },

  _load_geometries : function(event_cb){
    var _this = this;

    var mesh_resource = 'ship.' + this.type + '.mesh_geometry';
    var mesh_geometry = Omega.ShipMesh.geometry_for(this.type);
    Omega.UI.ResourceLoader.load(mesh_resource, mesh_geometry, event_cb);

    var missile_resource = 'ship.' + this.type + '.missile_geometry';
    var missile_geometry = Omega.ShipMissile.geometry_for(this.type);
    Omega.UI.ResourceLoader.load(missile_resource, missile_geometry, event_cb);
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_components(event_cb);
    this._load_effects();
    this._load_audio();
    this._load_textures(event_cb);
    this._load_geometries(event_cb);
    this._loaded_gfx();
  }
};
