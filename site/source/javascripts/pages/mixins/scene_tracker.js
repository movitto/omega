/* Omega Page Scene Tracker Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity_tracker"

Omega.Pages.SceneTracker = {

  /// Wire up scene change handler
  handle_scene_changes : function(){
    var _this = this;
    if(!Omega.has_listener_for(this.canvas, 'set_scene_root'))
      this.canvas.addEventListener('set_scene_root',
        function(change){ _this.scene_change(change.data); })
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
      /// TODO caching scene loc w/ invalidation mechanism
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
  }
};

$.extend(Omega.Pages.SceneTracker, Omega.EntityTracker);
