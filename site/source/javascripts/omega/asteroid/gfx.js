/* Omega Asteroid Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_asteroid_gfx = function(config, event_cb){
  var gfx = {};
  Omega.Asteroid.gfx = gfx;

  Omega.load_asteroid_template_mesh(config, function(mesh){
     gfx.mesh = mesh;
     Omega.Asteroid.prototype.loaded_resource('template_mesh', mesh);
     if(event_cb) event_cb();
  });
};

Omega.init_asteroid_gfx = function(config, asteroid, event_cb){
  Omega.load_asteroid_mesh(function(mesh){
    asteroid.mesh = mesh;
    asteroid.mesh.omega_entity = asteroid;
    asteroid.mesh.omega_obj = asteroid.mesh;
    asteroid.components = [asteroid.mesh];
    asteroid.loaded_resource('mesh',  asteroid.mesh);
    if(asteroid.location)
        asteroid.mesh.position.
          add(new THREE.Vector3(asteroid.location.x,
                                asteroid.location.y,
                                asteroid.location.z));
  });
};

///////////////////////////////////////// initializers

Omega.load_asteroid_template_mesh = function(config, event_cb){
  var texture_path    = config.url_prefix + config.images_path +
                        config.resources.asteroid.material;
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.asteroid.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.asteroid.rotation;
  var scale           = config.resources.asteroid.scale;

  var texture         = THREE.ImageUtils.loadTexture(texture_path, {},
                                                     event_cb);
  var mesh_material   = new THREE.MeshLambertMaterial({ map: texture });

  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var mesh = new THREE.Mesh(mesh_geometry, mesh_material);
    if(scale)
      mesh.scale.set(scale[0], scale[1], scale[2]);
    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
    }
    event_cb(mesh);
  }, geometry_prefix);
};

Omega.load_asteroid_mesh = function(cb){
  Omega.Asteroid.prototype.retrieve_resource('template_mesh',
    function(template_mesh){
      var mesh = template_mesh.clone();
      cb(mesh);
    });
};
