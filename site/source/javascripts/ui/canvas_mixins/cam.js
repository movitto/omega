/* Omega JS Canvas Camera Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasCameraManager = {
  // Reset camera to original position
  reset_cam : function(){
    if(!this.cam || !this.cam_controls) return;

    this.stop_following();
    var default_position = this.page.config.cam.position;
    var default_target   = this.page.config.cam.target;

    this.cam_controls.object.position.set(default_position[0],
                                          default_position[1],
                                          default_position[2]);

	  this.cam_controls.target = new THREE.Vector3();
    this.cam_controls.target.set(default_target[0],
                                 default_target[1],
                                 default_target[2]);
    this.cam_controls.update();

    this.entity_container.hide();
  },

  // Focus the scene camera on the specified location
  focus_on : function(pos){
    this.cam_controls.target.set(pos.x,pos.y,pos.z);
    this.cam_controls.update();
  },

  /// return bool indicating if cam is following component
  is_following : function(component){
    return this.following_component == component;
  },

  /// instruct canvas cam to follow location
  follow : function(component){
    if(this.following_component) this.stop_following();
    this.following_component = component;
    component.add(this.cam);
  },

  // high level helper to follow an entity assuming
  // it has a 'position_tracker'
  follow_entity : function(entity){
    if(!this.cam || !this.cam_controls) return;
    if(this.is_following(entity.position_tracker())) return;

    this.cam.position.set(500, 500, 500);
    this.follow(entity.position_tracker());
    this.cam_controls.update();
  },

  /// instruct canvas cam to stop following location
  stop_following : function(){
    if(this.following_component)
      this.following_component.remove(this.cam);
    this.following_component = null
  }
};
