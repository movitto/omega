/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/solar_system/gfx"

Omega.SolarSystem = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.interconnections = [];

  this.children   = [];
  $.extend(this, parameters);

  this.bg = Omega.str_to_bg(this.id);

  this.children = Omega.convert_entities(this.children);
  this.location = Omega.convert_entity(this.location)
};

Omega.SolarSystem.prototype = {
  json_class : 'Cosmos::Entities::SolarSystem',

  toJSON : function(){
    var children_json = [];
    for(var c = 0; c < this.children.length; c++)
      children_json.push(this.children[c].toJSON())

    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            children   : children_json};
  },

  asteroids : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::Asteroid';
    });
  },

  planets : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::Planet';
    });
  },

  jump_gates : function(){
    return $.grep(this.children, function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::JumpGate';
    });
  },

  update_children_from : function(entities){
    /// update jg endpoints from entities / add interconnections
    var gates = this.jump_gates();
    for(var g = 0; g < gates.length; g++){
      var gate = gates[g];
      var system = $.grep(entities, function(entity){
        return entity.id == gate.endpoint_id;
      })[0];

      if(system != null){
        gate.endpoint = system;
        this.add_interconn(system);
      }
    }
  },

  clicked_in : function(canvas){
    canvas.set_scene_root(this);
  },

  text_opts : {
    height        : 12,
    width         : 5,
    curveSegments : 2,
    font          : 'helvetiker',
    size          : 48
  },

  async_gfx : 2,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.SolarSystem.gfx) !== 'undefined') return;
    Omega.load_solar_system_gfx(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_solar_system_gfx(config, this, event_cb);
  },

  add_interconn : function(endpoint){
    Omega.add_solar_system_interconn(this, endpoint);
  }
};

$.extend(Omega.SolarSystem.prototype, Omega.SolarSystemEffectRunner);

// return the solar system with the specified id
Omega.SolarSystem.with_id = function(id, node, cb){
  node.http_invoke('cosmos::get_entity',
    'with_id', id,
    function(response){
      var sys = null;
      if(response.result) sys = new Omega.SolarSystem(response.result);
      cb(sys);
    });
}

THREE.EventDispatcher.prototype.apply( Omega.SolarSystem.prototype );
