/* Omega JS Tracker
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// Entity Tracker mixin, add to classes & use to track scene and user entities
///
/// Assumes the class this is being mixed into:
///   - extends Omega.UI.Registry
///   - has a session property (Omega.Session instance)
///   - has a node property    (Omega.Node instance)
///   - has a canvas property  (Omega.UI.Canvas instance)
Omega.UI.Tracker = {

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
    entities.in_root = $.grep(entities.manu, function(entity){
      return entity.system_id == root.id;
    });
    entities.not_in_root = $.grep(entities.manu, function(entity){
      return entity.system_id != root.id;
    });
    entities.stop_tracking = $.grep(entities.not_in_root, function(entity){
      /// stop tracking entities not in scene
      return entities.not_user_owned.indexOf(entity) != -1;
    });
    entities.start_tracking = $.grep(entities.in_root, function(entity){
      /// track entities in scene
      return entities.not_user_owned.indexOf(entity) != -1;
    });
    return entities;
  },

  /// Track cosmos-level system-wide events
  track_system_events : function(root){
    this.node.ws_invoke('manufactured::unsubscribe',  'system_jump');
    if(root.json_class != "Cosmos::Entities::SolarSystem") return;
    this.node.ws_invoke('manufactured::subscribe_to', 'system_jump', 'to', root.id);
  },

  /// Stop tracking manu entities in scene
  stop_tracking_scene_entities : function(entities){
    for(var e = 0; e < entities.stop_tracking.length; e++){
      var entity = entities.stop_tracking[e];
      this.stop_tracking_entity(entity);
    }
  },

  /// Start tracking manu entities in scene
  track_scene_entities : function(root, entities){
    this.stop_tracking_scene_entities(entities);
    if(root.json_class != "Cosmos::Entities::SolarSystem") return;

    for(var e = 0; e < entities.start_tracking.length; e++){
      var entity = entities.start_tracking[e];
      this.track_entity(entity);
    }
  },

  /// Refresh latest scene planet location from server
  sync_scene_planets : function(root){
    var _this = this;
    if(root.json_class != "Cosmos::Entities::SolarSystem") return;

    var planets = root.planets();
    for(var p = 0; p < planets.length; p++){
      var planet = planets[p];
      this.node.http_invoke('motel::get_location',
        'with_id', planet.location.id,
        function(response){
          if(response.result){
            planet.location = new Omega.Location(response.result);
            if(_this.canvas.is_root(root.id)){
              _this.canvas.reload(planet, function(){
                planet.update_gfx();
              });
            }
          }
        });
    }
  },

  /// Synchronize entities in system from server
  sync_scene_entities : function(root, entities, cb){
    if(root.json_class != "Cosmos::Entities::SolarSystem") return;

    for(var e = 0; e < entities.in_root.length; e++){
      var entity = entities.in_root[e];
      if(entity.alive() && !this.canvas.has(entity.id))
        this.canvas.add(entity);
    }

    /// retrieve all entities in the current system
    Omega.Ship.under(root.id, this.node, cb);
    Omega.Station.under(root.id, this.node, cb);
  },

  /// Track specified manu entity
  track_entity : function(entity){
    if(entity.json_class == 'Manufactured::Ship')
      this.track_ship(entity);
    else if(entity.json_class == 'Manufactured::Station')
      this.track_station(entity);
  },

  /// Stop tracking specified manu entity
  stop_tracking_entity : function(entity){
    if(entity.json_class == 'Manufactured::Ship')
      this.stop_tracking_ship(entity);
    else
      this.stop_tracking_station(entity);
  },

  /// Track all ship motel and manu callbacks
  track_ship : function(entity){
    var distance = this.config.ship_movement;
    var rotation = this.config.ship_rotation;

    /// track strategy,stops,movement,rotation
    this.node.ws_invoke('motel::track_strategy', entity.location.id);
    this.node.ws_invoke('motel::track_stops',    entity.location.id);
    this.node.ws_invoke('motel::track_movement', entity.location.id, distance);
    this.node.ws_invoke('motel::track_rotation', entity.location.id, rotation);

    /// track mining, offense, defense
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'resource_collected');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'mining_stopped');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'attacked');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'attacked_stop');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'defended');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'defended_stop');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'destroyed_by');
  },

  /// Stop tracking all ship motel and manu callbacks
  stop_tracking_ship : function(entity){
    this.node.ws_invoke('motel::remove_callbacks', entity.location.id);
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  /// Track all station motel and manu callbacks
  track_station : function(entity){
    /// track construction
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'construction_complete');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'construction_failed');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'partial_construction');
  },

  /// Stop tracking all station motel and manu callbacks
  stop_tracking_station : function(entity){
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  }
};
