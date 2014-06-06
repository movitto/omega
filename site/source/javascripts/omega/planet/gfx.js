/* Omega Planet Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx"
//= require "omega/planet/axis"
//= require "omega/planet/mesh"

// Planet Gfx Mixin

Omega.PlanetGfx = {
  /// TODO: centralize number of planet textures / make configurable
  _num_textures : 7,

  async_gfx : 1,

  include_axis : true,

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded(this.type)) return;
    Omega.Planet.gfx         = Omega.Planet.gfx || {};

    var gfx                  = {};
    gfx.mesh                 = new Omega.PlanetMesh({config: config,
                                                     type: this.type,
                                                     event_cb: event_cb});
    gfx.axis                 = new Omega.PlanetAxis();

    Omega.Planet.gfx[this.type]   = gfx;
    this._loaded_gfx(this.type);
  },

  /// Intiialize local system graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(config, event_cb);

    this.mesh = Omega.Planet.gfx[this.type].mesh.clone();
    this.mesh.omega_entity = this;
    this.mesh.material =
      new Omega.PlanetMaterial.load(config, this.type, event_cb);

    var orientation = this.location.orientation();
    this.axis = Omega.Planet.gfx[this.type].axis.clone();
    this.axis.set_orientation(orientation[0],
                              orientation[1],
                              orientation[2]);
    this.axis.omega_entity = this;
    if(this.include_axis)
      this.position_tracker().add(this.axis.mesh);

    this.spin_scale = (Math.random() * 0.75) + 0.5;

    this.update_gfx();

    this._calc_orbit();
    this._orbit_angle = this._current_orbit_angle();
    this.orbit_line = new Omega.OrbitLine({orbit: this.orbit});

    this.last_moved = new Date();
    this.components = [this.position_tracker(), this.mesh.tmesh, this.orbit_line.line];
    this._gfx_initializing = false;
    this._gfx_initialized  = true;
  },

  /// Update local system graphics on core entity changes
  update_gfx : function(){
    this.mesh.update();

    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);
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
    this.mesh.spin(elapsed / 2 * this.spin_scale);

    this.update_gfx();
    this.last_moved = curr;
  }
}

$.extend(Omega.PlanetGfx, Omega.EntityGfx);
