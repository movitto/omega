/* Omega Star JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/star/gfx"

Omega.Star = function(parameters){
  this.components        = [];
  this.shader_components = [];
  this.effects_timestamp = new Date();
  this.color             = 'FFFFFF';
  $.extend(this, parameters);

  this.color_int = parseInt('0x' + this.color);
  this.location = Omega.convert_entity(this.location)
};

Omega.Star.prototype = {
  constructor: Omega.Star,
  json_class : 'Cosmos::Entities::Star',

  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            color      : this.color,
            size       : this.size};
  },

  async_gfx : 2,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Star.gfx) !== 'undefined') return;
    Omega.load_star_gfx(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_star_gfx(config, this, event_cb);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Star.prototype );
