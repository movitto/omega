/* Omega Planet Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/planet/mesh"

// Planet Gfx Mixin

Omega.PlanetGfx = {
  /// TODO: centralize number of planet textures / move configurable
  _num_textures : 4,

  async_gfx : 1,

  load_gfx : function(config, event_cb){
    var colori = this.colori();

    if(typeof(Omega.Planet.gfx) === 'undefined') Omega.Planet.gfx = {};
    if(typeof(Omega.Planet.gfx[colori]) !== 'undefined') return;
    var gfx = {};

    gfx.mesh = new Omega.PlanetMesh(config, colori, event_cb);
    Omega.Planet.gfx[colori] = gfx;
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    var color = this.colori();
    this.mesh = Omega.Planet.gfx[color].mesh.clone();
    this.mesh.omega_entity = this;
    this.mesh.material =
      new Omega.PlanetMaterial.load(config, color, event_cb);
    this.update_gfx();

    this._calc_orbit();
    this.orbit_line = new Omega.PlanetOrbitLine(this.orbit);

    this.components = [this.mesh.tmesh, this.orbit_line.line];
  },

  update_gfx : function(){
    if(!this.location) return;
    if(this.mesh) this.mesh.update();
  },

  run_effects : function(){
    var ms   = this.location.movement_strategy;
    var curr = new Date();
    if(!this.last_moved){
      this.last_moved = curr;
      return;
    }

    var elapsed = curr - this.last_moved;
    var dist = ms.speed * elapsed / 1000;

    // get current angle, update, set
    var angle = this._current_orbit_angle();
    var new_angle = dist + angle;
    this._set_orbit_angle(new_angle);

    // spin the planet
    if(this.mesh) this.mesh.spin(elapsed / 1000);

    this.update_gfx();
    this.last_moved = curr;
  }
}
