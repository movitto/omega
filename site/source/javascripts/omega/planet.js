/* Omega Planet JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// TODO also load planet moons

//= require 'ui/canvas/orbit'
//= require 'omega/planet/gfx'

Omega.Planet = function(parameters){
  this.type = 0,
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert_entity(this.location)
};

Omega.Planet.prototype = {
  constructor: Omega.Planet,
  json_class : 'Cosmos::Entities::Planet',

  /// Update this planet's mutable properties from specified planet
  update : function(planet){
    this.location.update(planet.location);
  },

  /// Return planet in JSON format
  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            type       : this.type,
            size       : this.size};
  },

  /// Follow planets with camera on click
  clicked_in : function(canvas){
    canvas.follow_entity(this);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Planet.prototype );
$.extend(Omega.Planet.prototype, Omega.PlanetGfx);
$.extend(Omega.Planet.prototype, Omega.OrbitHelpers);
