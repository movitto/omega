/* Omega JS Tracker
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// Entity Tracker mixin, add to classes & use to track scene and user entities
Omega.EntityTracker = {
  /// Track cosmos-level system-wide events
  track_system_events : function(root){
    this.node.ws_invoke('manufactured::subscribe_to', 'system_jump', 'to',   root.id);
    this.node.ws_invoke('manufactured::subscribe_to', 'system_jump', 'from', root.id);
  },

  // Stop tracking cosmos-level system wide events
  stop_tracking_system_events : function(){
    this.node.ws_invoke('manufactured::unsubscribe',  'system_jump');
  },

  /// Stop tracking manu entities in scene
  stop_tracking_scene_entities : function(entities){
    for(var e = 0; e < entities.stop_tracking.length; e++){
      var entity = entities.stop_tracking[e];
      this.stop_tracking_entity(entity);
    }
  },

  /// Refresh latest scene planet location from server
  sync_scene_planets : function(root){
    var planets = root.planets();
    for(var p = 0; p < planets.length; p++){
      this._sync_scene_planet(root, planets[p]);
    }
  },

  /// Sync individual planet from server
  _sync_scene_planet : function(root, planet){
    var _this = this;
    this.node.http_invoke('motel::get_location',
      'with_id', planet.location.id,

      /// TODO accept / use generic callback parameter here, remove dependency on this.canvas
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
  },

  /// Synchronize entities in system from server
  sync_scene_entities : function(root, entities, cb){
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
    var distance = Omega.Config.ship_movement;
    var rotation = Omega.Config.ship_rotation;

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
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'transferred_to');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'transferred_from');
  },

  /// Stop tracking all ship motel and manu callbacks
  stop_tracking_ship : function(entity){
    this.node.ws_invoke('motel::remove_callbacks', entity.location.id);
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  /// Track all station motel and manu callbacks
  track_station : function(entity){
    var distance = Omega.Config.ship_movement;

    /// track strategy,movement
    this.node.ws_invoke('motel::track_strategy', entity.location.id);
    this.node.ws_invoke('motel::track_movement', entity.location.id, distance);

    /// track construction
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'construction_complete');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'construction_failed');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'partial_construction');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'transferred_to');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'transferred_from');
  },

  /// Stop tracking all station motel and manu callbacks
  stop_tracking_station : function(entity){
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  /// Track user events
  track_user_events : function(user_id){
    this.node.ws_invoke('missions::subscribe_to', 'victory', 'user_id', user_id);
    this.node.ws_invoke('missions::subscribe_to', 'failed',  'user_id', user_id);
  }
};
