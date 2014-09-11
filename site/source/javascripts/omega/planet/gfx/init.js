/* Omega JS Planet Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx_stub"

Omega.PlanetGfxInitializer = {
  include_axis  : true,

  _init_mesh : function(){
    this.mesh              = this._retrieve_resource('mesh').clone();
    this.mesh.omega_entity = this;
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
    this._orbit_angle = this._orbit_angle_from_coords(this.location.coordinates());
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

    this._init_mesh();
    this._init_axis();
    this._init_orbit();
    this._init_components();
    this.spin_scale = (Math.random() * 0.75) + 0.5;

    this.update_gfx();
    this.last_moved = new Date();
    this._gfx_initializing = false;
    this._gfx_initialized  = true;
  }
};
