/* Omega Asteroid Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/loader"

Omega.AsteroidMeshMaterial = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                     Omega.Config.resources.asteroid.material;

  var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  this.material = new THREE.MeshLambertMaterial({ map: texture });
};

Omega.AsteroidMesh = function(args){
  if(!args) args = {};
  var mesh     = args['mesh'];
  var material = args['material'];
  var geometry = args['geometry'];

  if(mesh) this.tmesh = mesh;
  else if(material && geometry) this.tmesh = new THREE.Mesh(geometry, material);
  this.tmesh.omega_obj = this;
};

Omega.AsteroidMesh.prototype = {
  clone : function(){
    return new Omega.AsteroidMesh({mesh: this.tmesh.clone()});
  }
};

Omega.AsteroidMesh.geometry_paths = function(){
  var geometry_paths = Omega.Config.resources.asteroid.geometry.slice(0);
  for(var g = 0; g < geometry_paths.length; g++)
    geometry_paths[g] = Omega.Config.url_prefix + Omega.Config.images_path + geometry_paths[g];

  var geometry_prefix = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.meshes_path;
  return [geometry_paths, geometry_prefix]; 
};
