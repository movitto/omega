/* Omega Asteroid JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Asteroid = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert_entity(this.location)
};

Omega.Asteroid.prototype = {
  constructor: Omega.Asteroid,
  json_class : 'Cosmos::Entities::Asteroid',

  toJSON : function(){
    return {json_class : this.json_class,
            id         : this.id,
            name       : this.name,
            location   : this.location ? this.location.toJSON() : null,
            parent_id  : this.parent_id,
            color      : this.color,
            size       : this.size};
  },

  has_details : true,

  retrieve_details : function(page, details_cb){
    var title   = 'Asteroid: ' + this.name;
    var loc     = '@ ' + this.location.to_s();
    var details = title + '<br/>' +
                  loc   + '<br/>';
    details_cb(details);

    var _this = this;
    page.node.http_invoke('cosmos::get_resources', this.id,
      function(response){
        _this._resources_retrieved(response, details_cb);
      });
  },

  _resources_retrieved : function(response, cb){
    var resource_details = '';

    if(response.error){
      resource_details =
        'Could not load resources: ' + response.error.message;
    }else{
      var result = response.result;
      for(var r = 0; r < result.length; r++){
        var resource = result[r];
        var id   = 'Resource: ' + resource.id;
        var text = resource.quantity + ' of ' + resource.material_id;
        resource_details += id   + '<br/>' +
                            text + '<br/>';
      }
    }

    cb(resource_details);
  },

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

      Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, mesh_material);
        Omega.Asteroid.gfx.mesh = mesh;
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.Asteroid.prototype.loaded_resource('template_mesh', mesh);
        if(event_cb) event_cb();
      }, geometry_prefix);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized

    this.load_gfx(config, event_cb);

    var _this = this;
    Omega.Asteroid.prototype.retrieve_resource('template_mesh', function(template_mesh){
      _this.mesh = template_mesh.clone();
      if(_this.location)
        _this.mesh.position.add(new THREE.Vector3(_this.location.x,
                                                  _this.location.y,
                                                  _this.location.z));
      _this.mesh.omega_entity = _this;
      _this.components = [_this.mesh];
      _this.loaded_resource('mesh', _this.mesh);
    });
  }
};

Omega.UI.ResourceLoader.prototype.apply(Omega.Asteroid.prototype);
