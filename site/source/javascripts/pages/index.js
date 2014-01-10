/* Omega Index Page JS
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/effects_player"
//= require "ui/status_indicator"
//= require "ui/canvas"

//= require "ui/pages/index_nav"
//= require "ui/pages/index_dialog"

Omega.Pages.Index = function(){
  this.config  = Omega.Config;
  this.node    = new Omega.Node(this.config);
  this.entities = {};

  this.command_tracker  = new Omega.UI.CommandTracker({page : this})
  this.effects_player   = new Omega.UI.EffectsPlayer({page : this});
  this.dialog           = new Omega.UI.IndexDialog({page : this});
  this.nav              = new    Omega.UI.IndexNav({page : this});
  this.canvas           = new       Omega.UI.Canvas({page: this});
  this.status_indicator = new Omega.UI.StatusIndicator({page : this});
};

Omega.Pages.Index.prototype = {
  // entity getter / setter
  // specify id of entity to get & optional new value to set
  entity : function(){
    if(arguments.length > 1)
      this.entities[arguments[0]] = arguments[1];
    return this.entities[arguments[0]];
  },

  // return array of all entities
  all_entities : function(){
    // TODO exclude placeholder entities?
    return Omega.obj_values(this.entities);
  },

  wire_up : function(){
    this.nav.wire_up();

    /// wire up dialog
    this.dialog.wire_up();
    this.dialog.follow_node(this.node);

    this.canvas.wire_up();

    /// handle scene changes
    var _this = this;
    if(!Omega.has_listener_for(this.canvas, 'set_scene_root'))
      this.canvas.addEventListener('set_scene_root',
        function(change){ _this._scene_change(change.data); })

    /// wire up status_indicator
    this.status_indicator.follow_node(this.node, 'loading');
    Omega.UI.Loader.status_indicator = this.status_indicator;
  },

  /// cleanup index page operations
  unload : function(){
    this.unloading = true;
    this.ws.close();
  },

  validate_session : function(){
    var _this = this;
    this.session = Omega.Session.restore_from_cookie();
    /// TODO split out anon user session into third case where we: (?)
    /// - show login controls, load default entities
    if(this.session != null && this.session.user_id != this.config.anon_user){
      this.session.validate(this.node, function(result){
        if(result.error){
          _this._session_invalid();
        }else{
          _this._session_validated();
        }
      });
    }else{
      _this._session_invalid();
    }
  },

  _session_validated : function(){
    var _this = this;
    this.nav.show_logout_controls();
    this.canvas.controls.missions_button.show();

    /// refresh entity container, no effect if hidden / entity doesn't belong
    /// to user, else entity controls will now be shown
    this.canvas.entity_container.refresh();

    /// setup callback handlers
    this.handle_events();

    // grab universe id
    Omega.UI.Loader.load_universe(this, function(){
      _this._load_user_entities();
    });
  },

  _load_user_entities : function(){
    var _this = this;

    /// load entities owned by user
    Omega.Ship.owned_by(this.session.user_id, this.node,
      function(ships) { _this.process_entities(ships); });
    Omega.Station.owned_by(this.session.user_id, this.node,
      function(stations) { _this.process_entities(stations); });
  },

  _session_invalid : function(){
    var _this = this;

    if(_this.session) _this.session.clear_cookies();
    _this.session = null;
    this.nav.show_login_controls();

    // login as anon
    var anon = new Omega.User({id : this.config.anon_user,
                               password : this.config.anon_pass});
    Omega.Session.login(anon, this.node, function(result){
      if(result.error){
        //_this.dialog.show_critical_error_dialog();
      }else{
        /// setup callback handlers
        _this.handle_events();

        Omega.UI.Loader.load_universe(_this, function(){
          _this._load_default_entities();
        });
      }
    });
  },

  _load_default_entities : function(){
    // load systems w/ most ships/stations
    var _this = this;
    Omega.Stat.get('systems_with_most', ['entities', 5], this.node,
      function(stat_result){
        if(stat_result){
          for(var s = 0; s < stat_result.value.length; s++){
            Omega.UI.Loader.load_system(stat_result.value[s], _this,
              function(solar_system) { _this.process_system(solar_system); });
          }
        }
      });

  },

/// FIXME selected entity not dissapearing / being unselected on scene change
  _scene_change : function(change){
    var _this    = this;
    var root     = change.root,
        old_root = change.old_root;

    /// assuming user owned entities are always tracked,
    /// and do not to be manipulated here
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

    this._track_system_events(root, old_root);
    this._track_scene_entities(entities, root, old_root);
    this._sync_scene_entities(entities,  root, old_root);
    this._sync_scene_planets(entities,  root, old_root);

    /// remove galaxy particle effects from canvas scene
    if(old_root && old_root.json_class == 'Cosmos::Entities::Galaxy')
      this.canvas.remove(old_root);

    /// add galaxy particle effects to canvas scene
    if(root.json_class == 'Cosmos::Entities::Galaxy')
      this.canvas.add(root);

    /// set scene background
    this.canvas.skybox.set(root.bg);

    /// add skybox to scene
    if(!this.canvas.has(this.canvas.skybox.id))
      this.canvas.add(this.canvas.skybox);
  },

  _track_system_events : function(root, old_root){
    this.node.ws_invoke('manufactured::unsubscribe',  'system_jump');
    this.node.ws_invoke('manufactured::subscribe_to', 'system_jump', 'to', root.id);
  },

  _track_scene_entities : function(entities, root, old_root){
    for(var e = 0; e < entities.stop_tracking.length; e++){
      var entity = entities.stop_tracking[e];
      if(entity.json_class == 'Manufactured::Ship')
        this.stop_tracking_ship(entity);
      else
        this.stop_tracking_station(entity);
    }

    if(root.json_class != "Cosmos::Entities::SolarSystem") return;

    for(var e = 0; e < entities.start_tracking.length; e++){
      var entity = entities.start_tracking[e];
      this.track_entity(entity);
    }
  },

  /// refresh latest scene planet location from server
  _sync_scene_planets : function(entities, root, old_root){
    if(root.json_class != "Cosmos::Entities::SolarSystem") return;

    var _this = this;
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

  _sync_scene_entities : function(entities, root, old_root){
    if(root.json_class != "Cosmos::Entities::SolarSystem") return;
    var _this = this;

    for(var e = 0; e < entities.in_root.length; e++){
      var entity = entities.in_root[e];
      if(entity.alive() && !this.canvas.has(entity.id))
        this.canvas.add(entity);
    }

    /// retrieve all entities in the current system, add to scene if missing
    Omega.Ship.under(root.id, this.node, function(ships){
      _this._process_retrieved_scene_entities(ships, entities);
    });

    Omega.Station.under(root.id, this.node, function(stations){
      _this._process_retrieved_scene_entities(stations, entities);
    });
  },

  _process_retrieved_scene_entities : function(entities, entity_map){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      entity.update_system(this.entity(entity.system_id));

      var local      = this.entity(entity.id);
      var user_owned = this.session != null ?
                         entity.user_id == this.session.user_id : false;
      var same_scene = this.canvas.root.id == entity.system_id;
      var in_scene   = this.canvas.has(entity.id);
      var tracking   = $.grep(entity_map.start_tracking, function(track_entity){
                         return track_entity.id == entity.id; })[0] != null;

      /// same assumption as in _scene_change above, that
      /// user owned entities are already being tracked
      if(!user_owned){
        this.entity(entity.id, entity);

        if(entity.alive()){
          if(same_scene && !in_scene)
            this.canvas.add(entity);
          if(!tracking)
            this.track_entity(entity);

          /// also add entity to entity_list if not present
          if(!this.canvas.controls.entities_list.has(entity.id)){
            var item = {id: entity.id, text: entity.id, data: entity};
            this.canvas.controls.entities_list.add(item);
          }
        }
      }
    }
  },

  handle_events : function(){
    var events = Omega.UI.CommandTracker.prototype.motel_events.concat(
                 Omega.UI.CommandTracker.prototype.manufactured_events);
    for(var e = 0; e < events.length; e++)
      this.command_tracker.track(events[e]);
  },

  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  process_entity : function(entity){
    var _this = this;
    this.entity(entity.id, entity);
    if(!this.canvas.controls.entities_list.has(entity.id)){
      var item = {id: entity.id, text: entity.id, data: entity};
      this.canvas.controls.entities_list.add(item);
    }

    var system = Omega.UI.Loader.load_system(entity.system_id, this,
      function(solar_system) { _this.process_system(solar_system); });
    if(system && system != Omega.UI.Loader.placeholder)
      entity.update_system(system);

    this.track_entity(entity);
  },

  track_entity : function(entity){
    if(entity.json_class == 'Manufactured::Ship')
      this.track_ship(entity);
    else if(entity.json_class == 'Manufactured::Station')
      this.track_station(entity);
  },

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

  stop_tracking_ship : function(entity){
    this.node.ws_invoke('motel::remove_callbacks', entity.location.id);
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  track_station : function(entity){
    /// TODO track jumps
    /// track construction
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'construction_complete');
    this.node.ws_invoke('manufactured::subscribe_to', entity.id, 'partial_construction');
  },

  stop_tracking_station : function(entity){
    this.node.ws_invoke('manufactured::remove_callbacks', entity.id);
  },

  process_system : function(system){
    if(system == null) return;
    var _this = this;
    var sitem  = {id: system.id, text: system.name, data: system};
    this.canvas.controls.locations_list.add(sitem);

    for(var e in this.entities){
      if(this.entities[e].system_id == system.id)
        this.entities[e].update_system(system);
      else if(this.entities[e].json_class == 'Cosmos::Entities::SolarSystem')
        this.entities[e].update_children_from(this.all_entities());
    }

    var galaxy = Omega.UI.Loader.load_galaxy(system.parent_id, this,
      function(galaxy) { _this.process_galaxy(galaxy) });
    if(galaxy && galaxy != Omega.UI.Loader.placeholder)
      galaxy.set_children_from(this.all_entities());

    // load missing jump gate endpoints
    var gates = system.jump_gates();
    for(var j = 0; j < gates.length; j++){
      var gate = gates[j];
      Omega.UI.Loader.load_system(gate.endpoint_id, this,
        function(system){
          _this.process_system(system);
        });
    }
    system.update_children_from(this.all_entities());
  },

  process_galaxy : function(galaxy){
    if(galaxy == null) return;
    var gitem  = {id: galaxy.id, text: galaxy.name, data: galaxy};
    this.canvas.controls.locations_list.add(gitem);

    galaxy.set_children_from(this.all_entities());
  }
};

$(document).ready(function(){
  if(Omega.Test) return;

  // immediately start preloading missing resources
  Omega.UI.Loader.preload();

  // wire up / startup ui
  var index = new Omega.Pages.Index();
  index.wire_up();
  index.canvas.setup();
  index.effects_player.wire_up();
  index.effects_player.start();
  index.validate_session();

  $(window).on('beforeunload', function(){
    index.unload();
  });
});
