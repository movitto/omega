/* Omega Asteroid JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Asteroid = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.Asteroid.prototype = {
  json_class : 'Cosmos::Entities::Asteroid',

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Asteroid.gfx) !== 'undefined') return;
    Omega.Asteroid.gfx = {};

    //// mesh
      var texture_path    = config.url_prefix + config.images_path + config.resources.asteroid.material;
      var geometry_path   = config.url_prefix + config.images_path + config.resources.asteroid.geometry;
      var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
      var rotation        = config.resources.asteroid.rotation;
      var scale           = config.resources.asteroid.scale;

      var texture         = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var mesh_material   = new THREE.MeshLambertMaterial({ map: texture });

      new THREE.JSONLoader().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, mesh_material);
        Omega.Asteroid.gfx.mesh = mesh;
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.Asteroid.prototype.dispatchEvent({type: 'loaded_template_mesh', data: mesh});
        event_cb();
      }, geometry_prefix);
  },

  retrieve_resource : function(resource, cb){
    switch(resource){
      case 'template_mesh':
        if(Omega.Asteroid.gfx && Omega.Asteroid.gfx.mesh){
          cb(Omega.Asteroid.gfx.mesh);
          return;
        }
        break;
      case 'mesh':
        if(this.mesh){
          cb(this.mesh);
          return;
        }
        break;
    }

    var _this = this;
    this.addEventListener('loaded_' + resource, function(evnt){
      if(evnt.target == _this) /// event interface defined on prototype, need to distinguish instances
        cb(evnt.data);
    });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized

    this.load_gfx(config, event_cb);

    var _this = this;
    Omega.Asteroid.prototype.retrieve_resource('template_mesh', function(){
      _this.mesh = Omega.Asteroid.gfx.mesh.clone();
      if(_this.location)
        _this.mesh.position.add(new THREE.Vector3(_this.location.x,
                                                  _this.location.y,
                                                  _this.location.z));
      _this.mesh.omega_entity = _this;
      _this.components = [_this.mesh];
      _this.dispatchEvent({type: 'loaded_mesh', data: _this.mesh});
    });
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Asteroid.prototype );
