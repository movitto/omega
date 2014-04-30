/* Omega Asteroid Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/asteroid/mesh"

// Asteroid GFX Mixin
Omega.AsteroidGfx = {
  async_gfx : 1,

  // Returns location which to render gfx components, overridable
  scene_location : function(){
    return this.location;
  },

  /// True / false if station gfx have been preloaded
  gfx_loaded : function(){
    return !!(Omega.Asteroid.gfx);
  },

  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;
    var gfx = {};

    Omega.AsteroidMesh.load_templates(config, function(templates){
      gfx.meshes = templates;
      if(event_cb) event_cb();
    });

    Omega.Asteroid.gfx = gfx;
  },

  /// True / false if station gfx have been initialized
  gfx_initialized : function(){
    return !!(this._gfx_initialized);
  },

  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    /// pick a random mesh from those available
    var num_meshes = Omega.Asteroid.gfx.meshes.length;
    var mesh_num   = Math.floor(Math.random() * num_meshes);

    var _this = this;
    Omega.AsteroidMesh.load(mesh_num, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.components = [_this.mesh.tmesh];
      _this.update_gfx();
      _this.loaded_resource('mesh',  _this.mesh);
      _this._gfx_initialized = true;
    });
  },

  update_gfx : function(){
    var loc = this.scene_location();
    this.mesh.tmesh.position.set(loc.x, loc.y, loc.z);
  },

  run_effects : function(){}
};
