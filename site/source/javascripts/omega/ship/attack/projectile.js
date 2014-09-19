/* Omega Ship Projectile Base
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipProjectile = {
  init_projectile : function(args){
    this.init_mesh(args);

    var strategy = { distance : this.arrival_distance,
                     speed : this.speed, max_speed : this.speed,
                     acceleration : this.acceleration };
    this.location = new Omega.Location({movement_strategy : strategy});
    this.clock    = new THREE.Clock();
  },

  init_mesh : function(args){
    var mesh     = args['mesh'];
    var material = args['material'];
    var geometry = args['geometry'];

    if(mesh)                       this.mesh = mesh;
    else if(material && geometry)  this.mesh = new THREE.Mesh(geometry, material);
  },

  set_source : function(source){
    this.source = source;
    this.location.set(source.scene_location());
    this.location.set_orientation(this.launch_dir());
    this.location.update_ms_dir(this.location.orientation());
    this.location.update_ms_acceleration(this.location.orientation());
  },

  set_target : function(target){
    this.location.set_tracking(target.scene_location());
  },

  near_target : function(){
    return this.location.near_target();
  },

  launching : function(){
    return !this.launched &&
            this.location.distance_from(this.source.scene_location()) < this.launch_distance;
  },

  _mark_launched : function(){
    this.location.face_target();
    this.launched = true;
  },

  explode : function(){
    this.source.explosions.trigger(this.location.vector());
  },

  _face_target : function(delta){
    var rot_angle = this.rot_theta * delta;
    if(!this.location.facing_target(this.theta_tolerance)){
      this.location.angle_rotated = 0;
      this.location.rotate_orientation(rot_angle);
      this.location.update_ms_acceleration();
    }
  },

  _move_linear : function(delta){
    var distance = this.location.movement_strategy.speed * delta / 1000;
    this.location.move_linear(distance);
  },

  _update_component : function(){
    var components = this.components();
    for(var c = 0; c < components.length; c++){
      var component = components[c];
      component.rotation.setFromRotationMatrix(this.location.rotation_matrix());
      component.position.set(this.location.x,
                             this.location.y,
                             this.location.z);
    }
  }
};
