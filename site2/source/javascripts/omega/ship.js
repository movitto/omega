/* Omega Ship JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO orientations, updates on movement/rotation/attack/defense/mining

Omega.Ship = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.Ship.prototype = {
  json_class : 'Manufactured::Ship',

  has_details : true,

  entity_details : function(){
    return "";
  },

  unselected : function(){
  },

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  trail_props : {
    plane : 3, lifespan : 20
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

    var particle_path     = config.url_prefix + config.images_path + '/particle.png';
    var particle_texture  = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);

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

    //// trails
      var trails = config.resources.ships[this.type].trails;
      Omega.Ship.gfx[this.type].trails = [];
      if(trails){
        var trail_material = new THREE.ParticleBasicMaterial({
          color: 0xFFFFFF, size: 20, map: particle_texture,
          blending: THREE.AdditiveBlending, transparent: true });

        for(var l = 0; l < trails.length; l++){
          var trail = trails[l];
          var geo   = new THREE.Geometry();

          var plane    = Omega.Ship.prototype.trail_props.plane;
          var lifespan = Omega.Ship.prototype.trail_props.lifespan;
          for(var i = 0; i < plane; ++i){
            for(var j = 0; j < plane; ++j){
              var pv = new THREE.Vector3(i, j, 0);
              pv.velocity = Math.random();
              pv.lifespan = Math.random() * lifespan;
              if(i >= plane / 4 && i <= 3 * plane / 4 &&
                 j >= plane / 4 && j <= 3 * plane / 4 ){
                   pv.lifespan *= 2;
                   pv.velocity *= 2;
              }
              pv.olifespan = pv.lifespan;
              geo.vertices.push(pv)
            }
          }

          var strail = new THREE.ParticleSystem(geo, trail_material);
          strail.position.set(trail[0], trail[1], trail[2]);
          strail.sortParticles = true;
          Omega.Ship.gfx[this.type].trails.push(strail);
        }
      }

    //// attack line
      var attack_material = new THREE.ParticleBasicMaterial({
        color: 0xFF0000, size: 20, map: particle_texture,
        blending: THREE.AdditiveBlending, transparent: true });
      var attack_geo = new THREE.Geometry();
      var attack_vector = new THREE.ParticleSystem(attack_geo, attack_material);
      attack_vector.sortParticles = true;
      Omega.Ship.gfx[this.type].attack_vector = attack_vector;


    //// mining line
      var mining_material = new THREE.LineBasicMaterial({color: 0x0000FF});
      var mining_geo      = new THREE.Geometry();
      var mining_vector   = new THREE.Line(mining_geo, mining_material);
      Omega.Ship.gfx[this.type].mining_vector = mining_vector;
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

    this.trails = [];
    for(var t = 0; t < Omega.Ship.gfx[this.type].trails.length; t++){
      var trail = Omega.Ship.gfx[this.type].trails[t].clone();
      if(this.location)
        trail.position.add(new THREE.Vector3(this.location.x,
                                             this.location.y,
                                             this.location.z));
      this.trails.push(trail);
    }

    this.attack_vector = Omega.Ship.gfx[this.type].attack_vector.clone();
    if(this.location) this.attack_vector.position.set(this.location.x,
                                                      this.location.y,
                                                      this.location.z);

    this.mining_vector = Omega.Ship.gfx[this.type].mining_vector.clone();
    if(this.location) this.mining_vector.position.set(this.location.x,
                                                      this.location.y,
                                                      this.location.z);
  },

  run_effects : function(){
    // animate lamps
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }

    // animate trails
    var plane    = Omega.Ship.prototype.trail_props.plane,
        lifespan = Omega.Ship.prototype.trail_props.lifespan;
    for(var t = 0; t < this.trails.length; t++){
      var trail = this.trails[t];
      var p = plane*plane;
      while(p--){
        var pv = trail.geometry.vertices[p]
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = pv.olifespan;
        }
      }
      trail.geometry.__dirtyVertices = true;
    }

    /// TODO animate attack particles
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
