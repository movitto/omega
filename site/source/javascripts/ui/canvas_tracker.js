/* Omega JS Canvas Tracker
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/tracker"

/// Canvas Tracker Mixin, extends Omega.UI.Tracker to couple tracking
/// results to manipulate canvas & controls
Omega.UI.CanvasTracker = {
  /// Invoked on Omega.UI.Canvas scene_change event
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

          this._add_nav_entity(entity);
        }
      }
    }
  },

  _add_nav_entity : function(entity){
    /// TODO skip if not alive?
    if(!this.canvas.controls.entities_list.has(entity.id)){
      var item = {id: entity.id, text: entity.id, data: entity};
      this.canvas.controls.entities_list.add(item);
    }
  },

  _add_nav_system : function(system){
    if(!this.canvas.controls.locations_list.has(system.id)){
      var sitem = {id: system.id, text: system.name, data: system};
      this.canvas.controls.locations_list.add(sitem);
    }
  },

  _add_nav_galaxy : function(galaxy){
    if(!this.canvas.controls.locations_list.has(galaxy.id)){
      var gitem = {id: galaxy.id, text: galaxy.name, data: galaxy};
      this.canvas.controls.locations_list.add(gitem);
    }
  },

  _store_entity : function(entity){
    var local = this.entity(entity.id);
    if(local) entity.cp_gfx(local);
    this.entity(entity.id, entity);

  },

  /// Process entities retrieved from server
  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  _load_entity_system : function(entity){
    var _this = this;
    var system = Omega.UI.Loader.load_system(entity.system_id, this,
      function(solar_system) { _this.process_system(solar_system); });
    if(system && system != Omega.UI.Loader.placeholder)
      entity.update_system(system);
  },

  /// Process entity retrieved from server
  process_entity : function(entity){
    /// store entity locally
    this._store_entity(entity);

    /// add to navigation
    this._add_nav_entity(entity);

    /// load system entity is in
    this._load_entity_system(entity);

    /// start tracking entity
    this.track_entity(entity);
  },

  _update_system_children : function(system){
    for(var e in this.entities){
      if(this.entities[e].system_id == system.id)
        this.entities[e].update_system(system);
      else if(this.entities[e].json_class == 'Cosmos::Entities::SolarSystem')
        this.entities[e].update_children_from(this.all_entities());
    }
  },

  _load_system_galaxy : function(system){
    var _this = this;
    var galaxy = Omega.UI.Loader.load_galaxy(system.parent_id, this,
      function(galaxy) { _this.process_galaxy(galaxy) });
    if(galaxy && galaxy != Omega.UI.Loader.placeholder)
      galaxy.set_children_from(this.all_entities());

  },

  _load_system_interconns : function(system){
    var _this = this;
    var gates = system.jump_gates();
    for(var j = 0; j < gates.length; j++){
      var gate = gates[j];
      Omega.UI.Loader.load_system(gate.endpoint_id, this,
        function(system){
          _this.process_system(system);
        });
    }
  },

  _process_system_on_refresh : function(system){
    if(system._process_on_refresh) return;

    var _this = this;
    system._process_on_refresh = function(){ _this.process_system(system); }
    system.removeEventListener('refreshed', system._process_on_refresh);
    system.addEventListener('refreshed',    system._process_on_refresh);
  },

  /// Process system retrieved from server
  process_system : function(system){
    if(system == null) return;

    /// add system to navigation & update references
    this._add_nav_system(system);
    this._update_system_children(system);
    this._load_system_galaxy(system);

    /// load missing jump gate endpoints, update children
    this._load_system_interconns(system);
    system.update_children_from(this.all_entities());

    /// process system whenever refreshed from server
    this._process_system_on_refresh(system);
  },

  _process_galaxy_on_refresh : function(galaxy){
    if(galaxy._process_on_refresh) return;

    var _this = this;
    galaxy._process_on_refresh = function(){ _this.process_galaxy(galaxy); }
    galaxy.removeEventListener('refreshed', galaxy._process_on_refresh);
    galaxy.addEventListener('refreshed',    galaxy._process_on_refresh);
  },

  _load_galaxy_interconns : function(galaxy){
    Omega.UI.Loader.load_interconnects(galaxy, this, function(){});
  },

  /// Process galaxy retrieved from server
  process_galaxy : function(galaxy){
    if(galaxy == null) return;

    /// add galaxy to navigation
    this._add_nav_galaxy(galaxy);

    /// update galaxy children
    galaxy.set_children_from(this.all_entities());

    /// load interconnections
    this._load_galaxy_interconns(galaxy);

    /// this process galaxy whenever refreshed from server
    this._process_galaxy_on_refresh(galaxy);
  }
};

$.extend(Omega.UI.CanvasTracker, Omega.UI.Tracker);
