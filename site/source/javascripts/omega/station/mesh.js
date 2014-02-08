/* Omega Station Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationMeshMaterial = function(config, type, event_cb){
  var texture_path =
    config.url_prefix + config.images_path +
    config.resources.stations[type].material;

  var texture =
    THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);

  $.extend(this, new THREE.MeshLambertMaterial({map: texture, overdraw: true}));
};

Omega.StationMesh = function(mesh){
  /// three.js mesh
  this.tmesh         =   mesh;
  mesh.omega_obj = this;

  this.base_position = [0,0,0];
  this.base_rotation = [0,0,0];
};

Omega.StationMesh.prototype = {
  clone : function(){
    return new Omega.StationMesh(this.tmesh.clone());
  },

  base_position_vector : function(){
    return new THREE.Vector3(this.base_position[0],
                             this.base_position[1],
                             this.base_position[2])
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    =   entity.location;

    /// set mesh position
    this.tmesh.position.set(loc.x, loc.y, loc.z);
  }
};

/// async template mesh loader
Omega.StationMesh.load_template = function(config, type, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.stations[type].geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.stations[type].rotation;
  var offset          = config.resources.stations[type].offset;
  var scale           = config.resources.stations[type].scale;
  
  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.Station.gfx[type].mesh_material;
    var mesh = new THREE.Mesh(mesh_geometry, material);

    var smesh = new Omega.StationMesh(mesh);

    if(offset){
      mesh.position.set(offset[0], offset[1], offset[2]);
      smesh.base_position = offset;
    }

    if(scale) mesh.scale.set(scale[0], scale[1], scale[2]);

    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
      smesh.base_rotation = rotation;
    }

    cb(smesh);
    Omega.Station.prototype.loaded_resource('template_mesh_' + type, smesh);
  }, geometry_prefix);
};
  
/// async mesh loader
Omega.StationMesh.load = function(type, cb){
  Omega.Station.prototype.retrieve_resource('template_mesh_' + type,
    function(template_mesh){
      var smesh = template_mesh.clone();

      /// so mesh materials can be independently updated:
      smesh.tmesh.material = Omega.Station.gfx[type].mesh_material.clone();

      /// copy custom attrs required later
      smesh.base_position = template_mesh.base_position;
      smesh.base_rotation = template_mesh.base_rotation;

      cb(smesh);
    });
};
