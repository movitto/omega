/* Omega Asteroid Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/loader"

Omega.AsteroidMesh = function(args){
  if(!args) args = {};
  var mesh = args['mesh'];

  this.tmesh = mesh;
  mesh.omega_obj = this;
};

Omega.AsteroidMesh.prototype = {
  clone : function(){
    return new Omega.AsteroidMesh({mesh: this.tmesh.clone()});
  }
};

/// async template mesh loader
Omega.AsteroidMesh.load_template = function(config, cb){
  var texture_path    = config.url_prefix + config.images_path +
                        config.resources.asteroid.material;
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.asteroid.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.asteroid.rotation;
  var scale           = config.resources.asteroid.scale;

  var texture         = THREE.ImageUtils.loadTexture(texture_path, {});
  var mesh_material   = new THREE.MeshLambertMaterial({ map: texture });

  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var mesh  = new THREE.Mesh(mesh_geometry, mesh_material);
    var amesh = new Omega.AsteroidMesh({mesh: mesh});

    if(scale) mesh.scale.set(scale[0], scale[1], scale[2]);
      
    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
    }

    cb(amesh);
    Omega.Asteroid.prototype.loaded_resource('template_mesh', amesh);
  }, geometry_prefix);
};

/// async mesh loader
Omega.AsteroidMesh.load = function(cb){
  Omega.Asteroid.prototype.retrieve_resource('template_mesh',
    function(template_mesh){
      cb(template_mesh.clone());
    });
};
