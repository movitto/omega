/* Omega Asteroid Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/asteroid/mesh"

// Asteroid GFX Mixin
Omega.AsteroidGfx = {
  load_gfx : function(config, event_cb){
    if(typeof(Omega.Asteroid.gfx) !== 'undefined') return;
    var gfx = {};
    Omega.Asteroid.gfx = gfx;

    Omega.AsteroidMesh.load_template(config, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    })
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
    });
  },

  update_gfx : function(){
    if(this.location)
      this.mesh.tmesh.position.add(this.location.vector());
  },

  run_effects : function(){}
};
