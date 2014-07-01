/* Omega Asteroid Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx"
//= require "omega/asteroid/mesh"

// Asteroid GFX Mixin
Omega.AsteroidGfx = {
  /// TODO update to include increased # of ast meshes
  async_gfx : 1,

  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;
    var gfx = {};

    Omega.AsteroidMesh.load_templates(config, function(templates){
      gfx.meshes = templates;
      if(event_cb) event_cb();
    });

    Omega.Asteroid.gfx = gfx;
    this._loaded_gfx();
  },

  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    /// pick a random mesh from those available
    var num_meshes = config.resources.asteroid.geometry.length;
    var mesh_num   = Math.floor(Math.random() * num_meshes);

    var _this = this;
    Omega.AsteroidMesh.load(mesh_num, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.position_tracker().add(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh',  _this.mesh);
      _this._gfx_initialized = true;
    });

    this.components = [this.position_tracker()];
  },

  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);
  },
};

$.extend(Omega.AsteroidGfx, Omega.EntityGfx);
