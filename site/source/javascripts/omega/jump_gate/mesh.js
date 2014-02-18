/* Omega Jump Gate Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateMeshMaterial = function(config, event_cb){
  var texture_path =
    config.url_prefix + config.images_path +
    config.resources.jump_gate.material;

  var texture =
    THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

  texture.wrapS     = texture.wrapT    = THREE.RepeatWrapping;
  texture.repeat.x  = texture.repeat.y = 5;

  this.material = new THREE.MeshLambertMaterial({ map: texture });
};

Omega.JumpGateMesh = function(mesh){
  this.tmesh = mesh;
  mesh.omega_obj = this;

  this.base_position = [0,0,0];
};

Omega.JumpGateMesh.prototype = {
  clone : function(){
    var mesh = new Omega.JumpGateMesh(this.tmesh.clone());
    mesh.base_position = this.base_position;
    return mesh;
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.tmesh.position.
      set(loc.x + this.base_position[0],
          loc.y + this.base_position[1],
          loc.z + this.base_position[2]);
  },

  run_effects : function(){
    /// TODO slowly rotate mesh
  }
};

/// async template mesh loader
Omega.JumpGateMesh.load_template = function(config, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.jump_gate.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.jump_gate.rotation;
  var offset          = config.resources.jump_gate.offset;
  var scale           = config.resources.jump_gate.scale;


  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.JumpGate.gfx.mesh_material.material;
    var mesh     = new THREE.Mesh(mesh_geometry, material);
    var jmesh    = new Omega.JumpGateMesh(mesh);

    if(offset){
      mesh.position.set(offset[0], offset[1], offset[2]);
      jmesh.base_position = offset;
    }

    if(scale)  mesh.scale.set(scale[0], scale[1], scale[2]);

    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
    }

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
