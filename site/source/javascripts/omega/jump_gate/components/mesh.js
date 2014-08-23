/* Omega Jump Gate Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateMeshMaterial = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                     Omega.Config.resources.jump_gate.material;

  var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  texture.wrapS     = texture.wrapT    = THREE.RepeatWrapping;
  texture.repeat.x  = texture.repeat.y = 5;
  texture.omega_id  = 'jump_gate.material';

  this.material = new THREE.MeshLambertMaterial({ map: texture });
};

Omega.JumpGateMesh = function(args){
  if(!args) args = {};
  var mesh     = args['mesh'];
  var material = args['material'];
  var geometry = args['geometry'];

  if(mesh) this.tmesh = mesh;
  else if(material && geometry) this.tmesh = new THREE.Mesh(geometry, material);

  this.tmesh.omega_obj = this;

  this.clock = new THREE.Clock();
};

Omega.JumpGateMesh.prototype = {
  clone : function(){
    var mesh = new Omega.JumpGateMesh({mesh : this.tmesh.clone()});
    return mesh;
  },

  run_effects : function(){
    var elapsed = this.clock.getDelta();
    this.tmesh.rotation.z += Math.PI / 30 * elapsed;
    this.tmesh.matrix.makeRotationFromEuler(this.tmesh.rotation);
  }
};

Omega.JumpGateMesh.geometry = function(){
  var geometry_path   = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.resources.jump_gate.geometry;
  var geometry_prefix = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.meshes_path;
  return [geometry_path, geometry_prefix];
};
