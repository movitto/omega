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

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Asteroid.gfx) !== 'undefined') return;
    var gfx = {};
    Omega.Asteroid.gfx = gfx;

    Omega.AsteroidMesh.load_template(config, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    })
  },

  /// True / false if station gfx have been initialized
  gfx_initialized : function(){
    return !!(this._gfx_initialized);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    var _this = this;
    Omega.AsteroidMesh.load(function(mesh){
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
