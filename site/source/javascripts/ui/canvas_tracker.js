/* Omega JS Canvas Tracker
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/tracker"

/// Canvas Tracker Mixin, extends Omega.UI.Tracker to couple tracking
/// results to manipulate canvas & controls
Omega.UI.CanvasTracker = {
  /// Handle Omega.UI.Canvas scene_change event
  scene_change : function(change){
    var _this    = this;
    var root     = change.root,
        old_root = change.old_root;

    var entities = this.entity_map(root);
    this.track_system_events(root);
    this.track_scene_entities(root, entities);
    this.sync_scene_entities(root, entities, function(retrieved){
      _this._process_retrieved_scene_entities(retrieved, entities);
    });
    this.sync_scene_planets(root);

    /// unselect currently selected entity (if any)
    this.canvas.entity_container.hide();

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

    /// add star dust to scene
    if(!this.canvas.has(this.canvas.star_dust.id))
      this.canvas.add(this.canvas.star_dust);
  },

  _process_retrieved_scene_entities : function(entities, entity_map){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      entity.update_system(this.entity(entity.system_id));

      var local      = this.entity(entity.id);
      var user_owned = this.session != null ?
                         entity.user_id == this.session.user_id : false;
      var same_scene = this.canvas.root && this.canvas.root.id == entity.system_id;
      var in_scene   = this.canvas.has(entity.id);
      var tracking   = $.grep(entity_map.start_tracking, function(track_entity){
                         return track_entity.id == entity.id; })[0] != null;

      /// same assumption as in _scene_change above, that
      /// user owned entities are already being tracked
      if(!user_owned){
        if(local) entity.cp_gfx(local);
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

  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  process_entity : function(entity){
    var _this = this;

    var local = this.entity(entity.id);
    if(local) entity.cp_gfx(local);
    this.entity(entity.id, entity);

    /// TODO skip if not alive?
    var item = {id: entity.id, text: entity.id, data: entity};
    if(!this.canvas.controls.entities_list.has(item.id))
      this.canvas.controls.entities_list.add(item);

    var system = Omega.UI.Loader.load_system(entity.system_id, this,
      function(solar_system) { _this.process_system(solar_system); });
    if(system && system != Omega.UI.Loader.placeholder)
      entity.update_system(system);

    this.track_entity(entity);
  },

  process_system : function(system){
    if(system == null) return;
    var _this = this;
    var sitem  = {id: system.id, text: system.name, data: system};
    if(!this.canvas.controls.locations_list.has(sitem.id))
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
    if(!this.canvas.controls.locations_list.has(gitem.id))
      this.canvas.controls.locations_list.add(gitem);

    /// TODO load galaxy system interconnects (if not already loaded)
    /// implement cosmos::interconnections rjr method
    /// return hash of system id's to multi-dimentional array of connected system ids & locations

    galaxy.set_children_from(this.all_entities());
  },

  process_cosmos_entity : function(entity){
    if(entity.json_class == "Cosmos::Entities::SolarSystem")
      this.process_system(entity);
    else //if(entity.json_class == "Cosmos::Entities::Galaxy")
      this.process_galaxy(entity);
  }
};

$.extend(Omega.UI.CanvasTracker, Omega.UI.Tracker);
