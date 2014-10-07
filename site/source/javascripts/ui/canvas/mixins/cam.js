/* Omega JS Canvas Camera Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasCameraManager = {
  default_position_for : function(entity){
    return entity ? Omega.Config.cam.position[entity.json_class] : [0,0,0];
  },

  // Reset camera to original position
  reset_cam : function(){
    if(!this.cam || !this.cam_controls) return;

    this.stop_following();
    var default_position = this.default_position_for(this.root);
    var default_target   = Omega.Config.cam.target;

    this.cam_controls.object.position.set(default_position[0],
                                          default_position[1],
                                          default_position[2]);

	  this.cam_controls.target = new THREE.Vector3();
    this.cam_controls.target.set(default_target[0],
                                 default_target[1],
                                 default_target[2]);
    this.cam_controls.update();

    /// XXX need to force raise event to trigger handlers incase camera
    /// properties not changed
    this.cam_controls.dispatchEvent({type : 'change'});

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

  /// high level helper to follow an entity assuming
  /// it has a position_tracker or location_tracker
  follow_entity : function(entity, args){
    if(!this.cam || !this.cam_controls) return;

             args = args || {};
    var distance  = args['distance'] || [500, 500, 500];
    var component = args['with_orientation'] ? entity.location_tracker() :
                                               entity.position_tracker();

    if(this.is_following(component)) return;

    this.cam.position.set(distance[0], distance[1], distance[2]);
    this.follow(component);
    this.cam_controls.update();
  },

  /// instruct canvas cam to stop following location
  stop_following : function(){
    if(this.following_component)
      this.following_component.remove(this.cam);
    this.following_component = null
  }
};
