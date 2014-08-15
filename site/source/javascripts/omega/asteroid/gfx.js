/* Omega Asteroid Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"
//= require "omega/asteroid/mesh"

// Asteroid GFX Mixin
Omega.AsteroidGfx = {
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
  },

  init_mesh : function(){
    /// pick a random mesh from those available
    var num_meshes = Omega.AsteroidMesh.geometry_paths()[0].length;
    var mesh_num   = Math.floor(Math.random() * num_meshes);

    var _this = this;
    Omega.UI.AsyncResourceLoader.retrieve('asteroid.meshes', function(geometries){
      var material = _this._retrieve_resource('mesh_material').material;
      var geometry = geometries[mesh_num];
      var mesh = new Omega.AsteroidMesh({material: material, geometry: geometry});

      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.position_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this._gfx_initialized = true;
    });
  },

  init_components : function(){
    this.components = [this.position_tracker()];
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);
    this.init_mesh();
    this.init_components();
  },

  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);
  },
};

$.extend(Omega.AsteroidGfx, Omega.UI.CanvasEntityGfx);
