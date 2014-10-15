/* Omega JS Canvas Entities Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasEntitiesManager = {
  // Set the scene root entity
  set_scene_root : function(root){
    var old_root = this.root;
    this.clear();
    this.clear(this.farScene);
    this.root = root;
    this.reset_cam();
    var children = root.children;
    for(var c = 0; c < children.length; c++){
      this.add(children[c]);
      this.add(children[c], this.farScene);
    }

    this.dispatchEvent({type: 'set_scene_root',
                        data: {root: root, old_root: old_root}});
  },

  /// Return bool indicating if scene is set to the specified root
  is_root : function(entity_id){
    return this.root != null && this.root.id == entity_id;
  },

  // Add specified entity to scene
  add : function(entity, scene){
    if(typeof(scene) === "undefined") scene = this.scene;

    var _this = this;
    entity.init_gfx(function(evnt){ _this._init_gfx(); });
    var components = entity.scene_components();
    for(var ec = 0; ec < components.length; ec++){
      var component = components[ec];
      scene.add(component);

      if(component.omega_obj && component.omega_obj.rendered_in)
        this.rendered_in.push(component);

      var children = component.getDescendants();
      for(var cc = 0; cc < children.length; cc++){
        var child = children[cc];
        if(child.omega_obj && child.omega_obj.rendered_in)
          this.rendered_in.push(child);
      }
    }

    if(this.page && this.page.effects_player && entity.has_effects())
      this.page.effects_player.add(entity);
    this.entities.push(entity.id);

    if(entity.added_to) entity.added_to(this, scene);
  },

  // Remove specified entity from scene
  remove : function(entity, scene){
    if(typeof(scene) === "undefined") scene = this.scene;

    var components = entity.scene_components();
    for(var ec = 0; ec < components.length; ec++){
      var component = components[ec];
      scene.remove(component);
      /// TODO renderer.deallocate(component);

      var index = this.rendered_in.indexOf(component);
      if(index != -1) this.rendered_in.splice(index, 1);

      var children = component.getDescendants();
      for(var cc = 0; cc < children.length; cc++){
        var child = children[cc];
        var index = this.rendered_in.indexOf(child);
        if(index != -1) this.rendered_in.splice(index, 1);
      }
    }

    if(this.page.effects_player && entity.has_effects())
      this.page.effects_player.remove(entity.id);
    var index = this.entities.indexOf(entity.id);
    if(index != -1) this.entities.splice(index, 1);

    if(entity.removed_from) entity.removed_from(this, scene);
  },

  // Remove entity from scene, invoke callback, readd entity to scene
  reload : function(entity, scene, cb){
    if(typeof(scene) === "undefined")
      scene = this.scene;
    else if(typeof(cb) === "undefined" && typeof(scene) === "function"){
      cb = scene;
      scene = this.scene;
    }

    var in_scene = this.has(entity.id);
    this.remove(entity, scene);

    /// XXX three.js queues all components added/removed until render, if an components
    /// is removed from one scene / added to another before render is called, the operation
    /// will not work properly. Force render here to get around this
    this.render();

    if(cb) cb(entity);
    if(in_scene) this.add(entity, scene);
  },

  // Clear entities from the scene
  clear : function(scene){
    if(typeof(scene) === "undefined") scene = this.scene;

    this.root = null;
    this.entities = [];
    this.rendered_in = [];
    this.following_loc = null;
    var scene_components = scene ? scene.getDescendants() : [];
    for(var c = 0; c < scene_components.length; c++)
      scene.remove(scene_components[c]);
  },

  /// return bool indicating if canvas has entity
  has : function(entity_id){
    return this.entities.indexOf(entity_id) != -1;
  }
};
