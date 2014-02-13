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

  colori : function(){
    return parseInt('0x' + this.color) % this._num_textures;
  },

  clicked_in : function(canvas){
    canvas.focus_on(this.location);
    canvas.follow(this.location);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Planet.prototype );
$.extend(Omega.Planet.prototype, Omega.PlanetGfx);
$.extend(Omega.Planet.prototype, Omega.PlanetOrbitHelpers);
