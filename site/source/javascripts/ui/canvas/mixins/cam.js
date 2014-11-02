/* Omega JS Canvas Camera Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.CanvasCameraManager = {
  default_cam_position_for : function(entity){
    return entity ? Omega.Config.cam.position[entity.json_class] : [0,0,0];
  },

  cam_restriction_for : function(entity){
    return entity && Omega.Config.cam.restriction[entity.json_class] ?
                     Omega.Config.cam.restriction[entity.json_class] :
                     Omega.Config.cam.restriction['default'];
  },

  /// Return current absolute cam position
  cam_world_position : function(){
    if(!this._cam_world) this._cam_world = new THREE.Vector3();
    return this._cam_world.getPositionFromMatrix(this.cam.matrixWorld);
  },

  // Reset camera to original position
  reset_cam : function(){
    if(!this.cam || !this.cam_controls) return;

    this.stop_following();
    var default_position = this.default_cam_position_for(this.root);
    var default_target   = Omega.Config.cam.target;

    this.cam_controls.object.position.set(default_position[0],
                                          default_position[1],
                                          default_position[2]);

	  this.cam_controls.target = new THREE.Vector3();
    this.cam_controls.target.set(default_target[0],
                                 default_target[1],
                                 default_target[2]);

    this.restrict_cam(this.cam_restriction_for(this.root));

    this.cam_controls.update();
    this._force_cam_update();

    this.entity_container.hide();
  },

  /// XXX for situations camera properties not changed
  /// and we need to force event to be raised to
  /// trigger handlers
  _force_cam_update : function(){
    this.cam_controls.dispatchEvent({type : 'change'});
  },

  /// Restrict cam controls
  restrict_cam : function(restrictions){
    if(restrictions['max']) this.cam_controls.maxDistance = restrictions['max'];
    if(restrictions['min']) this.cam_controls.minDistance = restrictions['min'];
  },

  // Focus the scene camera on the specified location
  focus_on : function(pos){
    this.cam_controls.target.set(pos.x,pos.y,pos.z);
    this.cam_controls.update();
  },

  /// return bool indicating if cam is following component
  is_following : function(component){
    return component ? (this.following_component == component) : !!(this.following_component);
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
    var component = entity.camera_tracker();

    if(this.is_following(component)) return;

    this.cam.position.set(distance[0], distance[1], distance[2]);
    this.cam_controls.target.set(0, 0, 0);
    this.follow(component);

    if(!args['no_restrict'])
      this.restrict_cam(this.cam_restriction_for(entity));

    this.cam_controls.update();
    this._force_cam_update();
  },

  /// instruct canvas cam to stop following location
  stop_following : function(){
    if(this.following_component)
      this.following_component.remove(this.cam);
    this.following_component = null

    this.restrict_cam(this.cam_restriction_for(this.root));
  }
};
