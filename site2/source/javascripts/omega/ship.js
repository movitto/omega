/* Omega Ship JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO trails, mining, attack lines

Omega.Ship = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.Ship.prototype = {
  json_class : 'Manufactured::Ship',

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Ship.gfx)            === 'undefined') Omega.Ship.gfx = {};
    if(typeof(Omega.Ship.gfx[this.type]) !== 'undefined') return;
    Omega.Ship.gfx[this.type] = {};

    var texture_path    = config.url_prefix + config.images_path + config.resources.ships[this.type].material;
    var geometry_path   = config.url_prefix + config.images_path + config.resources.ships[this.type].geometry;
    var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
    var rotation        = config.resources.ships[this.type].geometry.rotation;
    var offset          = config.resources.ships[this.type].geometry.offset;
    var scale           = config.resources.ships[this.type].geometry.scale;

    //// mesh
      /// each ship instance should set position of mesh
      var texture      = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      var material     = new THREE.MeshLambertMaterial({map: texture, overdraw: true});

      var _this = this;
      new THREE.JSONLoader().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, material);
        Omega.Ship.gfx[_this.type].mesh = mesh;
        if(offset)
          mesh.position.set(offset[0], offset[1], offset[2]);
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.Ship.prototype.dispatchEvent({type: 'loaded_template_mesh', data: mesh});
        event_cb();
      }, geometry_prefix);

    //// highlight effects
      /// each ship instance should set position of mesh
      var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
      var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                             shading: THREE.FlatShading } );
      var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
      highlight_mesh.position.set(Omega.Ship.prototype.highlight_props.x,
                                  Omega.Ship.prototype.highlight_props.y,
                                  Omega.Ship.prototype.highlight_props.z);
      highlight_mesh.rotation.set(Omega.Ship.prototype.highlight_props.rot_x,
                                  Omega.Ship.prototype.highlight_props.rot_y,
                                  Omega.Ship.prototype.highlight_props.rot_z);
      Omega.Ship.gfx[this.type].highlight = highlight_mesh;

    //// lamps
      var lamps = config.resources.ships[this.type].lamps;
      Omega.Ship.gfx[this.type].lamps = [];
      if(lamps){
        for(var l = 0; l < lamps.length; l++){
          var lamp  = lamps[l];
          var slamp = Omega.create_lamp(lamp[0], lamp[1]);
          slamp.position.set(lamp[2][0], lamp[2][1], lamp[2][2]);
          Omega.Ship.gfx[this.type].lamps.push(slamp);
        }
      }
  },

  /// invoked cb when resource is loaded, or immediately if resource is already loaded
  retrieve_resource : function(type, resource, cb){
    if(!cb && typeof(resource) === "function"){ /// XXX
       cb = resource; resource = type;
    }

    switch(resource){
      case 'template_mesh':
        if(Omega.Ship.gfx[type] && Omega.Ship.gfx[type].mesh){
          cb(Omega.Ship.gfx[type].mesh);
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
    Omega.Ship.prototype.retrieve_resource(this.type, 'template_mesh', function(){
      _this.mesh = Omega.Ship.gfx[_this.type].mesh.clone();
      if(_this.location)
        _this.mesh.position.set(_this.location.x,
                                _this.location.y,
                                _this.location.z);
      _this.mesh.omega_entity = _this;
      _this.dispatchEvent({type: 'loaded_mesh', data: _this.mesh});
    });

    this.highlight = Omega.Ship.gfx[this.type].highlight.clone();
    this.highlight.run_effects = Omega.Ship.gfx[this.type].highlight.run_effects; /// XXX
    if(this.location) this.highlight.position.set(this.location.x, this.location.y, this.location.z);

    this.components = [this.mesh, this.highlight];

    this.lamps = [];
    for(var l = 0; l < Omega.Ship.gfx[this.type].lamps.length; l++){
      var lamp = Omega.Ship.gfx[this.type].lamps[l].clone();
      lamp.run_effects = Omega.Ship.gfx[this.type].lamps[l].run_effects; /// XXX
      if(this.location)
        lamp.position.add(new THREE.Vector3(this.location.x,
                                            this.location.y,
                                            this.location.z));
      this.lamps.push(lamp);
      this.components.push(lamp);
    }
  },

  run_effects : function(){
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }
  }
};

// Return ships owned by the specified user
Omega.Ship.owned_by = function(user_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Ship', 'owned_by', user_id,
    function(response){
      var ships = [];
      if(response.result)
        for(var e = 0; e < response.result.length; e++)
          ships.push(new Omega.Ship(response.result[e]));
      cb(ships);
    });
}

THREE.EventDispatcher.prototype.apply( Omega.Ship.prototype );
