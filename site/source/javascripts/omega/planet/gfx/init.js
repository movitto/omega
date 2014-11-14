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
    this.location_tracker().add(this.mesh.tmesh);
  },

  _init_axis : function(){
    this.axis = this._retrieve_resource('axis').clone();
    this.axis.omega_entity = this;
    if(this.include_axis) this.location_tracker().add(this.axis.mesh);
  },

  _init_label : function(){
    this.label = new Omega.PlanetLabel({text : this.id});
    this.label.omega_entity = this;
    this.position_tracker().add(this.label.sprite);
  },

  _init_orbit : function(){
    this._calc_orbit();
    this._orbit_angle = this._orbit_angle_from_coords(this.location.coordinates());
  },

  _init_components : function(){
    this.position_tracker().add(this.location_tracker());
    this.components = [this.position_tracker(), this.camera_tracker()];
    this._add_orbit_line(Omega.OrbitLine.prototype.default_color, 3);
  },

  /// Initialize local planet graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);

    this._init_mesh();
    this._init_axis();
    this._init_label();
    this._init_orbit();
    this._init_components();
    this.spin_velocity = ((Math.random() * 0.25) + 0.25) / 4;

    this.update_gfx();
    this.last_moved = new Date();
    this._gfx_initializing = false;
    this._gfx_initialized  = true;
  }
};
