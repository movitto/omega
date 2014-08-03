/* Omega JS Canvas Tracker
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/tracker"

//= require "vendor/purl"

/// Canvas Tracker Mixin, extends Omega.UI.Tracker to couple tracking
/// results to manipulate canvas & controls
Omega.UI.CanvasTracker = {
  /// Load id of entity to autoload from url or config
  _default_root_id : function(){
    var url = $.url(window.location);
    var id  = url.param('root');
    if(!id && Omega.Config && Omega.Config.default_root)
      id = Omega.Config.default_root;
    return id;
  },

  /// Return type of entity & entity to autoload, nil if not set
  _default_root : function(){
    var id = this._default_root_id();
    if(!id) return null;

    var entity = null;
    if(id == 'random'){
      var entities = this.systems().concat(this.galaxies());
      entity = entities[Math.floor(Math.random()*entities.length)];
    }else{
      entity = $.grep(this.all_entities(), function(e){
        return e.id == id || e.name == id;
      })[0];
    }

    /// TODO load entity from server if id is set by entity is null?
    return entity;
  },

  /// Return bool indicating if a root entity should be autoloaded
  _should_autoload_root : function(){
    return !this.autoloaded && (this._default_root() != null);
  },

  /// Autoload root scene entity
  autoload_root : function(){
    var _this = this;

    this.autoloaded = true;
    var root = this._default_root();
    root.refresh(this.node, function(){
      _this.canvas.set_scene_root(root);
    });
  },

  /// Invoked on Omega.UI.Canvas scene_change event
  scene_change : function(change){
    var _this    = this;
    var root     = change.root,
        old_root = change.old_root;

    var entities = this.entity_map(root);

    /// unselect currently selected entity (if any)
    this.canvas.entity_container.hide();

    /// remove galaxy particle effects from canvas scene
    if(old_root){
      if(old_root.json_class == 'Cosmos::Entities::Galaxy')
        this.canvas.remove(old_root);

      else if(old_root.json_class == 'Cosmos::Entities::SolarSystem'){
        this.stop_tracking_system_events();
        this.stop_tracking_scene_entities(entities);
        this._unscale_system(old_root)
        //this._unscale_system_entities(old_root);
      }

    }else{
      /// TODO add option to toggle background audio in account preferences
      this.audio_controls.play(this.audio_controls.effects.background);
    }

    if(root.json_class == 'Cosmos::Entities::Galaxy'){
      /// adds galaxy particle effects to canvas scene
      this.canvas.add(root);

      if(this.canvas.has(this.canvas.skybox.id))
        this.canvas.remove(this.canvas.skybox, this.canvas.skyScene);

    }else if(root.json_class == 'Cosmos::Entities::SolarSystem'){
      this.track_system_events(root);
      this._scale_system(root);
      this.sync_scene_planets(root);
      this.sync_scene_entities(root, entities, function(retrieved){
        _this.process_entities(retrieved);
      });

      this.canvas.skybox.set(root.bg);

      if(!this.canvas.has(this.canvas.skybox.id))
        this.canvas.add(this.canvas.skybox, this.canvas.skyScene);
    }

    if(!this.canvas.has(this.canvas.star_dust.id))
      this.canvas.add(this.canvas.star_dust, this.canvas.skyScene);
  },

  // Wire up scene change handler
  handle_scene_changes : function(){
    var _this = this;
    if(!Omega.has_listener_for(this.canvas, 'set_scene_root'))
      this.canvas.addEventListener('set_scene_root',
        function(change){ _this.scene_change(change.data); })
  },

  /// Add entity to entities list if not present
  _add_nav_entity : function(entity){
    if(!this.canvas.controls.entities_list.has(entity.id)){
      var item = {id: entity.id, text: entity.id, data: entity};
      this.canvas.controls.entities_list.add(item);
    }
  },

  /// Add system to locations list if not present
  _add_nav_system : function(system){
    if(!this.canvas.controls.locations_list.has(system.id)){
      var sitem = {id: system.id, text: system.name,
                   data: system, index: 1};
      this.canvas.controls.locations_list.add(sitem);
    }
  },

  /// Add galaxy to locations list if no present
  _add_nav_galaxy : function(galaxy){
    if(!this.canvas.controls.locations_list.has(galaxy.id)){
      var gitem = {id: galaxy.id, text: galaxy.name,
                   data: galaxy, color : 'blue'};
      this.canvas.controls.locations_list.add(gitem);
    }
  },

  _scale_system : function(system){
    if(!Omega.Config.scale_system) return;

    var children = system.children;
    for(var c = 0; c < children.length; c++)
      this._scale_entity(children[c]);

    var manu = this.manu_entities();
    for(var c = 0; c < manu.length; c++)
      this._scale_entity(manu[c]);
  },

  _scale_entity : function(entity){
    var scale = Omega.Config.scale_system;
    if(entity.scene_location){
      /// backup original scene_location generator
      entity._scene_location = entity.scene_location;

      /// override scene location to scale all entities
      entity.scene_location = function(){
        return this.location.clone().set(this.location.divide(scale));
      };
    }

    /// scale orbit components
    if(entity.orbit)
      entity.orbit_line.line.scale.set(1/scale, 1/scale, 1/scale);

    if(entity.gfx_initialized()) entity.update_gfx();
  },

  _unscale_system : function(system){
    if(!Omega.Config.scale_system) return;

    var children = system.children;
    for(var c = 0; c < children.length; c++)
      this._unscale_entity(children[c]);
    /// TODO unscale manu entities
  },

  _unscale_entity : function(entity){
    if(entity._scene_location){
      entity.scene_location  = entity._scene_location;
      entity._scene_location = null;
    }

    if(entity.orbit) entity.orbit_line.line.scale.set(1, 1, 1);
  },

  /// Store entity in registry, copying locally-initialized
  /// attributes from original entity
  _store_entity : function(entity){
    var local = this.entity(entity.id);
    if(local) local.update(entity);
    else this.entity(entity.id, entity);
    return local || entity;
  },

  /// Process entities retrieved from server
  process_entities : function(entities){
    for(var e = 0; e < entities.length; e++){
      var entity = entities[e];
      this.process_entity(entity);
    }
  },

  /// Load system which entity is in
  _load_entity_system : function(entity){
    var _this = this;
    var system = Omega.UI.Loader.load_system(entity.system_id, this,
      function(solar_system) { _this.process_system(solar_system); });
    if(system && system != Omega.UI.Loader.placeholder)
      entity.update_system(system);
  },

  /// Process entity retrieved from server
  process_entity : function(entity){
    var user_owned = this.session != null &&
                     entity.user_id == this.session.user_id;

    var same_scene = this.canvas.root &&
                     this.canvas.root.id == entity.system_id;

    var in_scene   = this.canvas.has(entity.id);

    /// store entity locally
    entity = this._store_entity(entity);

    /// load system entity is in
    this._load_entity_system(entity);

    if(entity.alive()){
      /// add to navigation
      this._add_nav_entity(entity);

      /// add to scene if appropriate
      if(same_scene && !in_scene){
        this.canvas.add(entity);
        this._scale_entity(entity)
      }

      /// start tracking entity
      /// TODO only if not already tracking
      if(user_owned || same_scene) this.track_entity(entity);
    }
  },

  /// Update references to/from system
  _update_system_references : function(system){
    for(var e in this.entities){
      /// Set system on entities whose system_id == system.id
      if(this.entities[e].system_id == system.id)
        this.entities[e].update_system(system);

      /// Update all system's children from entities list
      /// (will update jg & other references to system)
      else if(this.entities[e].json_class == 'Cosmos::Entities::SolarSystem')
        this.entities[e].update_children_from(this.all_entities());
    }
  },

  /// Load galaxy which system is in
  _load_system_galaxy : function(system){
    var _this = this;
    var galaxy = Omega.UI.Loader.load_galaxy(system.parent_id, this,
      function(galaxy) { _this.process_galaxy(galaxy) });
    if(galaxy && galaxy != Omega.UI.Loader.placeholder)
      galaxy.set_children_from(this.all_entities());

  },

  /// Load all the systems the specified system has interconnections to
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

  /// Helper to wire up system refresh callback if not already wired up
  _process_system_on_refresh : function(system){
    /// If we've already registered callback just return
    if(system._process_on_refresh) return;

    /// Register callback to invoke process system on system refresh
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
    this._update_system_references(system);
    this._load_system_galaxy(system);

    /// load missing jump gate endpoints, update children
    this._load_system_interconns(system);
    system.update_children_from(this.all_entities());

    /// process system whenever refreshed from server
    this._process_system_on_refresh(system);
  },

  /// Helper to wire up galaxy refresh callback if not already wired up
  _process_galaxy_on_refresh : function(galaxy){
    /// If we've already registered allback just return
    if(galaxy._process_on_refresh) return;

    /// Register callback to invoke process galaxy on galaxy refresh
    var _this = this;
    galaxy._process_on_refresh = function(){ _this.process_galaxy(galaxy); }
    galaxy.removeEventListener('refreshed', galaxy._process_on_refresh);
    galaxy.addEventListener('refreshed',    galaxy._process_on_refresh);
  },

  /// Load all interconnections under galaxy
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
