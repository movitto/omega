/* Omega Asteroid JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/asteroid/commands"
//= require "omega/asteroid/gfx"

Omega.Asteroid = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert.entity(this.location)
};

Omega.Asteroid.prototype = {
  constructor: Omega.Asteroid,
  json_class : 'Cosmos::Entities::Asteroid',

  /// Return bool indicating if asteroid has the specified resource
  has_resource : function(id){
    return !!(this.resource(id));
  },

  /// Return resource for the specified id
  resource : function(id){
    return $.grep(this.resources, function(r){ return r.id == id; })[0];
  },

  /// Return Asteroid in JSON format
  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            color      : this.color,
            size       : this.size};
  },

  clicked_in : function(canvas){
    canvas.follow_entity(this);
  }
};

$.extend(Omega.Asteroid.prototype, Omega.AsteroidCommands);
$.extend(Omega.Asteroid.prototype, Omega.AsteroidGfx);
