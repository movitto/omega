/* Omega Ship Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMeshMaterial = function(args){
  if(!args) args = {};
  var type     = args['type'];
  var event_cb = args['event_cb'];

  var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                     Omega.Config.resources.ships[type].material;

  var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

  this.material = new THREE.MeshLambertMaterial({map: texture, overdraw: true});
};

Omega.ShipMesh = function(args){
  if(!args) args = {};
  var mesh     = args['mesh'];
  var material = args['material'];
  var geometry = args['geometry'];

  if(mesh) this.tmesh = mesh;
  else if(material && geometry) this.tmesh = new THREE.Mesh(geometry, material);
  
  this.tmesh.omega_obj = this;
};

Omega.ShipMesh.prototype = {
  clone : function(){
    return new Omega.ShipMesh({mesh : this.tmesh.clone()});
  }
};

Omega.ShipMesh.geometry_for = function(type){
  var geometry_path   = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.resources.ships[type].geometry;
  var geometry_prefix = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.meshes_path;
  return [geometry_path, geometry_prefix];
};
