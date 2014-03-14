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

  /// True/False if shared gfx are loaded
  gfx_loaded : function(){
    var colori = this.colori();
    return typeof(Omega.Planet.gfx)         !== 'undefined' &&
           typeof(Omega.Planet.gfx[colori]) !== 'undefined';
  },

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;
    Omega.Planet.gfx         = Omega.Planet.gfx || {};
    var colori               = this.colori();

    var gfx                  = {};
    gfx.mesh                 = new Omega.PlanetMesh({config: config,
                                                     color: colori,
                                                     event_cb: event_cb});
    Omega.Planet.gfx[colori] = gfx;
  },

  /// True / false if local system gfx have been initialized
  gfx_initialized : function(){
    return this.components.length > 0;
  },

  /// Intiialize local system graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    var color = this.colori();
    this.mesh = Omega.Planet.gfx[color].mesh.clone();
    this.mesh.omega_entity = this;
    this.mesh.material =
      new Omega.PlanetMaterial.load(config, color, event_cb);
    this.update_gfx();

    this._calc_orbit();
    if(!this._loc_on_orbit())
      this._adjust_loc_to_orbit();

    this.orbit_line = new Omega.OrbitLine({orbit: this.orbit});

    this.components = [this.mesh.tmesh, this.orbit_line.line];
    this.last_moved = new Date();
  },

  /// Update local system graphics on core entity changes
  update_gfx : function(){
    this.mesh.update();
  },

  /// Run local system graphics effects
  run_effects : function(){
    var curr = new Date();
    var elapsed = (curr - this.last_moved) / 1000;

    /// orbit planet around star
    var dist = this.location.movement_strategy.speed * elapsed;
    this._orbit_loc(dist);

    /// spin the planet
    this.mesh.spin(elapsed / 3);

    this.update_gfx();
    this.last_moved = curr;
  }
}
