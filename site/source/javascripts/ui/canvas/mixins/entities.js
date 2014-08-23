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
    this.root    = root;
    this.reset_cam();
    var children = root.children;
    for(var c = 0; c < children.length; c++)
      this.add(children[c]);
    this.animate();
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
    for(var cc = 0; cc < entity.components.length; cc++)
      scene.add(entity.components[cc]);

    if(this.page && this.page.effects_player && entity.has_effects())
      this.page.effects_player.add(entity);
    this.entities.push(entity.id);

    if(entity.added_to) entity.added_to(this, scene);
  },

  // Remove specified entity from scene
  remove : function(entity, scene){
    if(typeof(scene) === "undefined") scene = this.scene;

    for(var cc = 0; cc < entity.components.length; cc++)
      scene.remove(entity.components[cc]);

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
    if(cb) cb(entity);
    if(in_scene) this.add(entity, scene);
  },

  // Clear entities from the scene
  clear : function(scene){
    if(typeof(scene) === "undefined") scene = this.scene;

    this.root = null;
    this.entities = [];
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
