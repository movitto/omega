/* Omega JS Entity Registry
 *
 * Provides simple mechanism to store / track entities in memory
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.Registry = function(parameters){
  this.entities = {};

  $.extend(this, parameters);
};

Omega.UI.Registry.prototype = {
  /// entity getter / setter
  /// specify id of entity to get & optional new value to set
  entity : function(){
    if(arguments.length > 1)
      this.entities[arguments[0]] = arguments[1];
    return this.entities[arguments[0]];
  },

  /// return array of all entities
  all_entities : function(){
    // TODO exclude placeholder entities?
    return Omega.obj_values(this.entities);
  }
};
