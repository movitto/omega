/* Omega Page Registry Mixin
 *
 * Provides simple mechanism to store / track entities in memory
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Pages.HasRegistry = {
  init_registry : function(){
    this.clear_entities();
  },

  /// clear all entities
  clear_entities : function(){
    this.entities = {};
  },

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
  },

  //// return array of all systems in registry
  systems : function(){
    return $.grep(this.all_entities(), function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::SolarSystem';
    });
  },

  //// return array of all galaxies in registry
  galaxies : function(){
    return $.grep(this.all_entities(), function(c){
      return c.json_class &&
             c.json_class == 'Cosmos::Entities::Galaxy';
    });
  },

  /// return array of all manu entities in registry
  manu_entities : function(){
    return $.grep(this.all_entities(), function(c){
      return  c.json_class &&
             (c.json_class == 'Manufactured::Ship' ||
              c.json_class == 'Manufactured::Station');
    });
  },

  /// Generate a map of entities to be manipulated in variousw
  /// ways depending on their properties.
  //
  /// Assuming user owned entities are always tracked,
  /// and do not to be manipulated here
  entity_map : function(root){
    var _this = this;
    var entities = {};
    entities.manu = $.grep(this.all_entities(), function(entity){
      return (entity.json_class == 'Manufactured::Ship' ||
              entity.json_class == 'Manufactured::Station');
    });
    entities.user_owned = this.session == null ? [] :
      $.grep(entities.manu, function(entity){
        return entity.belongs_to_user(_this.session.user_id);
      });
    entities.not_user_owned = this.session == null ? entities.manu :
      $.grep(entities.manu, function(entity){
        return !entity.belongs_to_user(_this.session.user_id);
      });
    entities.stop_tracking = $.grep(entities.manu, function(entity){
      /// stop tracking entities not-user owned entities not in scene
      return entities.not_user_owned.indexOf(entity) != -1 &&
             entity.system_id != root.id;
    });
    return entities;
  },

  /// Return asteroid with specified resource
  asteroid_with_resource : function(id){
    var systems = this.systems();

    for(var s = 0; s < systems.length; s++){
      var asteroids = systems[s].asteroids();
      for(var a = 0; a < asteroids.length; a++){
        if(asteroids[a].has_resource(id))
          return asteroids[a];
      }
    }

    return null;
  }
};
