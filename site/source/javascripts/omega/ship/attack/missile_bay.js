/* Omega Ship Missile Bay Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMissileBay = function(args){
  if(!args) args = {};
  var event_cb   = args['event_cb'];
  var mesh       = args['mesh'];
  var material   = args['material'];
  var geometry   = args['geometry'];
  var animations = args['animations'];

  if(mesh)                       this.mesh = mesh;
  else if(material && geometry)  this.mesh = new THREE.SkinnedMesh(geometry, material);

  this.mesh.scale.set(5, 5, 5);
  this.mesh.omega_obj = this;

  this.clock    = new THREE.Clock();

  this.mesh_animation = animations[0];
  THREE.AnimationHandler.add(this.mesh_animation);
  this.animation = new THREE.Animation(this.mesh, this.mesh_animation.name,
                                       THREE.AnimationHandler.CATMULLROM);

  var _this = this;
  this.stop_timer =
    $.timer(function(){
      this.stop();
      _this.animation.stop();
    }, this.mesh_animation.length * 1000, false);
};

Omega.ShipMissileBay.prototype = {
  components : function(){
    return [this.mesh];
  },

  clone : function(){
    return new Omega.ShipMissileBay({mesh : this.mesh.clone()});
  },

  set_position : function(x, y, z){
    this.mesh.position.set(x, y, z);
  },

  trigger : function(){
    this.animation.play();
    this.stop_timer.play();
  },

  run_effects : function(){
    var delta = this.clock.getDelta();
    this.animation.update(delta);
  }
};

//$.extend(Omega.ShipMissileBay.prototype, Omega.UI.CanvasAnimation);

Omega.ShipMissileBay.geometry_for = function(type, cb){
  var geometry_path   = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.resources.missile_bay.geometry;
  var geometry_prefix = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.meshes_path;
  return [geometry_path, geometry_prefix];
};
