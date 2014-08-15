/* Omega Planet Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx"
//= require "omega/planet/axis"
//= require "omega/planet/mesh"

// Planet Gfx Mixin

Omega.PlanetGfx = {
  _num_textures : 7, /// TODO: centralize  / make configurable
  async_gfx     : 1,
  include_axis  : true,

  _load_mesh : function(event_cb){
    this._store_resource('mesh', new Omega.PlanetMesh({type: this.type, event_cb: event_cb}));
  },

  _load_axis : function(){
    this._store_resource('axis', new Omega.PlanetAxis());
  },

  /// Load shared graphics resources
  load_gfx : function(event_cb){
    if(this.gfx_loaded()) return;
    this._load_mesh(event_cb);
    this._load_axis();
    this._loaded_gfx();
  },

  _init_mesh : function(event_cb){
    this.mesh              = this._retrieve_resource('mesh').clone();
    this.mesh.omega_entity = this;
    this.mesh.material     = new Omega.PlanetMaterial.load(this.type, event_cb);
  },

  _init_axis : function(){
    this.axis = this._retrieve_resource('axis').clone();
    this.axis.omega_entity = this;

    var orientation = this.location.orientation();
    this.axis.set_orientation(orientation[0], orientation[1], orientation[2]);

    if(this.include_axis) this.position_tracker().add(this.axis.mesh);
  },

  _init_orbit : function(){
    this._calc_orbit();
    this._orbit_angle = this._current_orbit_angle();
    this.orbit_line = new Omega.OrbitLine({orbit: this.orbit});
  },

  _init_components : function(){
    this.components = [this.position_tracker(),
                       this.mesh.tmesh,
                       this.orbit_line.line];
  },

  /// Initialize local planet graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);

    this._init_mesh(event_cb);
    this._init_axis();
    this._init_orbit();
    this._init_components();
    this.spin_scale = (Math.random() * 0.75) + 0.5;

    this.update_gfx();
    this.last_moved = new Date();
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

$.extend(Omega.PlanetGfx, Omega.UI.CanvasEntityGfx);
