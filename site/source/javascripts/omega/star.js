/* Omega Star JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/star/gfx"

Omega.Star = function(parameters){
  this.components        = [];
  this.shader_components = [];
  this.effects_timestamp = new Date();
  this.type              = 'FFFFFF';
  $.extend(this, parameters);

  this.type_int = parseInt('0x' + this.type);
  this.location = Omega.convert.entity(this.location)
};

Omega.Star.prototype = {
  constructor: Omega.Star,
  json_class : 'Cosmos::Entities::Star',

  /// Return star in JSON format
  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            type       : this.type,
            size       : this.size};
  },

  clicked_in : function(canvas){
    canvas.reset_cam();
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Star.prototype );
$.extend(Omega.Star.prototype, Omega.StarGfx);

Omega.Star.types = function(){
  return Omega.Constraint._get(['star', 'type']);
};
