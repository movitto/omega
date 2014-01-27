/* Omega Asteroid JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/asteroid/commands"
//= require "omega/asteroid/gfx"

Omega.Asteroid = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert_entity(this.location)
};

Omega.Asteroid.prototype = {
  constructor: Omega.Asteroid,
  json_class : 'Cosmos::Entities::Asteroid',

  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            color      : this.color,
            size       : this.size};
  },

  has_details : true,

  _resources_retrieved : function(response, cb){
    var resource_details = '';

    if(response.error){
      resource_details =
        'Could not load resources: ' + response.error.message;
    }else{
      var result = response.result;
      for(var r = 0; r < result.length; r++){
        var resource = result[r];
        var id   = 'Resource: ' + resource.id;
        var text = resource.quantity + ' of ' + resource.material_id;
        resource_details += id   + '<br/>' +
                            text + '<br/>';
      }
    }

    cb(resource_details);
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Asteroid.gfx) !== 'undefined') return;
    Omega.load_asteroid_gfx(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_asteroid_gfx(config, this, event_cb);
  }
};

Omega.UI.ResourceLoader.prototype.apply(Omega.Asteroid.prototype);
$.extend(Omega.Asteroid.prototype, Omega.AsteroidCommands);
