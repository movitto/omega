/* Omega Planet JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// TODO also load planet moons

//= require 'omega/planet/orbit'
//= require 'omega/planet/gfx'

Omega.Planet = function(parameters){
  this.color = '000000';
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert_entity(this.location)
};

Omega.Planet.prototype = {
  constructor: Omega.Planet,
  json_class : 'Cosmos::Entities::Planet',

  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            color      : this.color,
            size       : this.size};
  },

  /// TODO: centralize number of planet textures
  _num_textures : 4,

  colori : function(){
    return parseInt('0x' + this.color) % this._num_textures;
  },

  async_gfx : 1,

  load_gfx : function(config, event_cb){
    var colori = this.colori();

    if(typeof(Omega.Planet.gfx) === 'undefined') Omega.Planet.gfx = {};
    if(typeof(Omega.Planet.gfx[colori]) !== 'undefined') return;
    Omega.load_planet_gfx(config, colori, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_planet_gfx(config, this, event_cb);
  },

  update_gfx : function(){
    if(!this.location) return;
    Omega.update_planet_gfx(this);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Planet.prototype );
$.extend(Omega.Planet.prototype, Omega.PlanetEffectRunner);
$.extend(Omega.Planet.prototype, Omega.PlanetOrbitHelpers);
$.extend(Omega.Planet.prototype, Omega.PlanetGfxUpdaters);
