/* Omega Ship Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMeshMaterial = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var type     = args['type'];
  var event_cb = args['event_cb'];

  var texture_path =
    config.url_prefix + config.images_path +
    config.resources.ships[type].material;

  var texture =
    THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

  $.extend(this, new THREE.MeshLambertMaterial({map: texture, overdraw: true}));
};

Omega.ShipMesh = function(args){
  if(!args) args = {};
  var mesh = args['mesh'];

  this.tmesh = mesh;
  this.tmesh.omega_obj = this;
};

Omega.ShipMesh.prototype = {
  clone : function(){
    return new Omega.ShipMesh({mesh : this.tmesh.clone()});
  }
};

/// async template mesh loader
Omega.ShipMesh.load_template = function(config, type, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.ships[type].geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  
  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.Ship.gfx[type].mesh_material;
    var mesh = new THREE.Mesh(mesh_geometry, material);

    var smesh = new Omega.ShipMesh({mesh : mesh});

    cb(smesh);
    Omega.Ship.prototype.loaded_resource('template_mesh_' + type, smesh);
  }, geometry_prefix);
};
  
/// async mesh loader
Omega.ShipMesh.load = function(type, cb){
  Omega.Ship.prototype.retrieve_resource('template_mesh_' + type,
    function(template_mesh){
      var smesh = template_mesh.clone();

      /// so mesh materials can be independently updated:
      smesh.tmesh.material = Omega.Ship.gfx[type].mesh_material.clone();

      cb(smesh);
    });
};
