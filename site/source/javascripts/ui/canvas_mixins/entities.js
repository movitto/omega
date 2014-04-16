/* Omega JS Canvas Entities Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasEntitiesManager = {
  // Set the scene root entity
  set_scene_root : function(root){
    var old_root = this.root;
    this.clear();
    this.reset_cam();
    this.root    = root;
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
  add : function(entity){
    /// XXX hacky but works for now:
    var _this = this;
    entity.sceneReload = function(evnt) { 
      if(entity.mesh == evnt.data && _this.has(entity.id))
        _this.reload(entity);
    };
    entity.addEventListener('loaded_mesh', entity.sceneReload);

    entity.init_gfx(this.page.config, function(evnt){ _this._init_gfx(); });
    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.add(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.add(entity.shader_components[cc]);

    if(this.page.effects_player)
      this.page.effects_player.add(entity);
    this.entities.push(entity.id);
  },

  // Remove specified entity from scene
  remove : function(entity){
    for(var cc = 0; cc < entity.components.length; cc++)
      this.scene.remove(entity.components[cc]);
    for(var cc = 0; cc < entity.shader_components.length; cc++)
      this.shader_scene.remove(entity.shader_components[cc]);

    /// remove event listener
    entity.removeEventListener('loaded_mesh', entity.sceneReload);

    if(this.page.effects_player)
      this.page.effects_player.remove(entity.id);
    var index = this.entities.indexOf(entity.id);
    if(index != -1) this.entities.splice(index, 1);
  },

  // Remove entity from scene, invoke callback, readd entity to scene
  reload : function(entity, cb){
    var in_scene = this.has(entity.id);
    this.remove(entity);
    if(cb) cb(entity);
    if(in_scene) this.add(entity);
  },

  // Clear entities from the scene
  clear : function(){
    this.root = null;
    this.entities = [];
    this.following_loc = null;
    var scene_components =
      this.scene ? this.scene.getDescendants() : [];
    var shader_scene_components =
      this.shader_scene ? this.shader_scene.getDescendants() : [];

    for(var c = 0; c < scene_components.length; c++)
      this.scene.remove(scene_components[c]);
    for(var c = 0; c < shader_scene_components.length; c++)
      this.shader_scene.remove(shader_scene_components[c]);
  },

  /// return bool indicating if canvas has entity
  has : function(entity_id){
    return this.entities.indexOf(entity_id) != -1;
  }
};
