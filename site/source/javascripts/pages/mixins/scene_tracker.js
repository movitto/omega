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
  }
};

$.extend(Omega.Pages.SceneTracker, Omega.EntityTracker);
