/* Omega Galaxy JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Galaxy = function(parameters){
  this.components = [];
  this.shader_components = [];

  this.children   = [];
  this.background = '';
  $.extend(this, parameters);

  this.bg = 'galaxy' + this.background;
  this.children = Omega.convert_entities(this.children);
};

Omega.Galaxy.prototype = {
  constructor : Omega.Galaxy,
  json_class : 'Cosmos::Entities::Galaxy'
};

// return the galaxy with the specified id
Omega.Galaxy.with_id = function(id, node, cb){
  node.http_invoke('cosmos::get_entity',
    'with_id', id,
    function(response){
      var galaxy = null;
      if(response.result) galaxy = new Omega.Galaxy(response.result);
      cb(galaxy);
    });
}
