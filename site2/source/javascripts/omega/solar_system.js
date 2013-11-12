/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystem = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.children   = [];
  this.background = '';
  $.extend(this, parameters);

  this.bg = 'system' + this.background;
  this.children = Omega.convert_entities(this.children);
};

Omega.SolarSystem.prototype = {
  constructor : Omega.SolarSystem,
  json_class : 'Cosmos::Entities::SolarSystem'
};

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
