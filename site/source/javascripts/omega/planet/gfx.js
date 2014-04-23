/* Omega Planet Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/planet/mesh"

// Planet Gfx Mixin

Omega.PlanetGfx = {
  /// TODO: centralize number of planet textures / make configurable
  _num_textures : 4,

  async_gfx : 1,

  // Returns location which to render gfx components, overridable
  scene_location : function(){
    return this.location;
  },

  /// True/False if shared gfx are loaded
  gfx_loaded : function(){
    return typeof(Omega.Planet.gfx)            !== 'undefined' &&
           typeof(Omega.Planet.gfx[this.type]) !== 'undefined';
  },

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;
    Omega.Planet.gfx         = Omega.Planet.gfx || {};
    var type                 = this.type;

    var gfx                  = {};
    gfx.mesh                 = new Omega.PlanetMesh({config: config,
                                                     type: type,
                                                     event_cb: event_cb});
    Omega.Planet.gfx[type] = gfx;
  },

  /// True / false if local planet gfx have been initialized
  gfx_initialized : function(){
    return !!(this._gfx_initialized);
  },

  /// Intiialize local system graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    var type = this.type;
    this.mesh = Omega.Planet.gfx[type].mesh.clone();
    this.mesh.omega_entity = this;
    this.mesh.material =
      new Omega.PlanetMaterial.load(config, type, event_cb);
    this.position_tracker = new THREE.Object3D();
    this.update_gfx();

    this._calc_orbit();
    this._orbit_angle = this._current_orbit_angle();
    this.orbit_line = new Omega.OrbitLine({orbit: this.orbit});

    this.last_moved = new Date();
    this.components = [this.position_tracker, this.mesh.tmesh, this.orbit_line.line];
    this._gfx_initialized = true;
  },

  /// Update local system graphics on core entity changes
  update_gfx : function(){
    this.mesh.update();

    var loc = this.scene_location();
    this.position_tracker.position.set(loc.x, loc.y, loc.z);
  },

  /// Run local system graphics effects
  run_effects : function(){
    var ms   = this.location.movement_strategy;
    var curr = new Date();
    var elapsed = (curr - this.last_moved) / 1000;

    // update orbit angle
    this._orbit_angle += ms.speed * elapsed;
    this._set_orbit_angle(this._orbit_angle);

    // spin the planet
    this.mesh.spin(elapsed / 2);

    this.update_gfx();
    this.last_moved = curr;
  }
}
