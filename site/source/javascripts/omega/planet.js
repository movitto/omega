/* Omega Planet JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// TODO also load planet moons

//= require 'ui/canvas/orbit'
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
            color      : this.color,
            size       : this.size};
  },

  /// Return the color as an integer.
  ///
  /// Since planets are represented graphically via a specified number of
  /// textures, we only need to support that many planet "colors" and thus
  /// we mod (%) the Omega Planet color via that value here
  colori : function(){
    return parseInt('0x' + this.color) % this._num_textures;
  },

  /// Follow planets with camera on click
  clicked_in : function(canvas){
    canvas.cam.position.set(500, 500, 500);
    canvas.follow(this.tracker_obj);
    canvas.cam_controls.update();
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Planet.prototype );
$.extend(Omega.Planet.prototype, Omega.PlanetGfx);
$.extend(Omega.Planet.prototype, Omega.OrbitHelpers);
