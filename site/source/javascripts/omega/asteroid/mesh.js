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

// Async Asteroid template meshes loader
Omega.AsteroidMesh.load_templates = function(config, cb){
  var texture_path    = config.url_prefix + config.images_path +
                        config.resources.asteroid.material;
  var geometry_paths  = config.resources.asteroid.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;

  var texture         = THREE.ImageUtils.loadTexture(texture_path, {});
  var mesh_material   = new THREE.MeshLambertMaterial({ map: texture });

  var loaded_templates = [];

  for(var g = 0; g < geometry_paths.length; g++){
    var geometry_path = config.url_prefix + config.images_path +
                        geometry_paths[g];
    Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
      var mesh  = new THREE.Mesh(mesh_geometry, mesh_material);
      var amesh = new Omega.AsteroidMesh({mesh: mesh});
      loaded_templates.push(amesh);

      var all_loaded = loaded_templates.length == geometry_paths.length;
      if(all_loaded){
        cb(loaded_templates);
        Omega.Asteroid.prototype.loaded_resource('template_meshes',
                                                 loaded_templates);
      }
    }, geometry_prefix);
  }
};

// Async Asteroid mesh loader
Omega.AsteroidMesh.load = function(num, cb){
  Omega.Asteroid.prototype.retrieve_resource('template_meshes',
    function(template_meshes){
      var template_mesh = template_meshes[num];
      cb(template_mesh.clone());
    });
};
