/* Omega Jump Gate Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateMeshMaterial = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];

  var texture_path =
    config.url_prefix + config.images_path +
    config.resources.jump_gate.material;

  var texture =
    THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

  texture.wrapS     = texture.wrapT    = THREE.RepeatWrapping;
  texture.repeat.x  = texture.repeat.y = 5;

  this.material = new THREE.MeshLambertMaterial({ map: texture });
};

Omega.JumpGateMesh = function(args){
  if(!args) args = {};
  var mesh = args['mesh'];

  this.tmesh = mesh;
  this.tmesh.omega_obj = this;

  this.clock = new THREE.Clock();
};

Omega.JumpGateMesh.prototype = {
  clone : function(){
    var mesh = new Omega.JumpGateMesh({mesh : this.tmesh.clone()});
    return mesh;
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.scene_location();
    this.tmesh.position.set(loc.x, loc.y, loc.z);
  },

  run_effects : function(){
    var elapsed = this.clock.getDelta();
    this.tmesh.rotation.z += Math.PI / 30 * elapsed;
    this.tmesh.matrix.makeRotationFromEuler(this.tmesh.rotation);
  }
};

/// async template mesh loader
Omega.JumpGateMesh.load_template = function(config, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.jump_gate.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;


  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.JumpGate.gfx.mesh_material.material;
    var mesh     = new THREE.Mesh(mesh_geometry, material);
    var jmesh    = new Omega.JumpGateMesh({mesh : mesh});

    cb(jmesh);
    Omega.JumpGate.prototype.loaded_resource('template_mesh', jmesh);
  }, geometry_prefix);

};
  
/// async mesh loader
Omega.JumpGateMesh.load = function(config, cb){
  Omega.JumpGate.prototype.retrieve_resource('template_mesh',
    function(template_mesh){
      var mesh = template_mesh.clone();
      cb(mesh);
    });
};
