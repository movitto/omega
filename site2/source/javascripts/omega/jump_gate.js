/* Omega JumpGate JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGate = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);
};

Omega.JumpGate.prototype = {
  json_class : 'Cosmos::Entities::JumpGate',

  particle_plane_size :  20,

  particle_lifespan   : 200,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.JumpGate.gfx) !== 'undefined') return;
    Omega.JumpGate.gfx = {};

    //// mesh
      var texture_path    = config.url_prefix + config.images_path + config.resources.jump_gate.material;
      var geometry_path   = config.url_prefix + config.images_path + config.resources.jump_gate.geometry;
      var geometry_prefix = config.url_prefix + config.images_path + config.meshes_path;
      var rotation        = config.resources.jump_gate.geometry.rotation;
      var offset          = config.resources.jump_gate.geometry.offset;
      var scale           = config.resources.jump_gate.geometry.scale;

      var texture         = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
      texture.wrapS       = texture.wrapT    = THREE.RepeatWrapping;
      texture.repeat.x    = texture.repeat.y = 5;
      var mesh_material   = new THREE.MeshLambertMaterial({ map: texture });

      new THREE.JSONLoader().load(geometry_path, function(mesh_geometry){
        var mesh = new THREE.Mesh(mesh_geometry, mesh_material);
        Omega.JumpGate.gfx.mesh = mesh;
        if(offset)
          mesh.position.set(offset[0], offset[1], offset[2]);
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
        Omega.JumpGate.prototype.dispatchEvent({type: 'loaded_template_mesh', data: mesh});
        event_cb();
      }, geometry_prefix);

    //// lamp
      Omega.JumpGate.gfx.lamp = Omega.create_lamp(10, 0xff0000);

    //// particles
      var particle_path = config.url_prefix + config.images_path + "/particle.png";
      var texture       = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
      var lifespan      = Omega.JumpGate.prototype.particle_lifespan,
          plane         = Omega.JumpGate.prototype.particle_plane_size;
      var particles_material =
        new THREE.ParticleBasicMaterial({
          color: 0x0000FF, size        : 20,
          map  : texture,  transparent : true,
          blending: THREE.AdditiveBlending
        });

      var particles = new THREE.Geometry();
      for(var i = 0; i < plane; ++i){
        for(var j = 0; j < plane; ++j){
          var pv = new THREE.Vector3(i, j, 0);
          pv.velocity = Math.random();
          pv.lifespan = lifespan;
          pv.moving = false;
          particles.vertices.push(pv)
        }
      }

      var particle_system = new THREE.ParticleSystem(particles, particles_material);
      particle_system.sortParticles = true;
      Omega.JumpGate.gfx.particles = particle_system;

    //// selection sphere
      /// each jump gate instance should override radius in the geometry instance to set to trigger distance
      var radius   = 300, segments = 32, rings = 32;
      var geometry = new THREE.SphereGeometry(radius, segments, rings);
      var material = new THREE.MeshBasicMaterial({color       : 0xffffff,
                                                  transparent : true,
                                                  opacity     : 0.1});

      Omega.JumpGate.gfx.selection_sphere =
        new THREE.Mesh(geometry, material);
  },

  /// invoked cb when resource is loaded, or immediately if resource is already loaded
  retrieve_resource : function(resource, cb){
    switch(resource){
      case 'template_mesh':
        if(Omega.JumpGate.gfx && Omega.JumpGate.gfx.mesh){
          cb(Omega.JumpGate.gfx.mesh);
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
    Omega.JumpGate.prototype.retrieve_resource('template_mesh', function(){
      _this.mesh = Omega.JumpGate.gfx.mesh.clone();
      if(_this.location)
        _this.mesh.position.add(new THREE.Vector3(_this.location.x,
                                                  _this.location.y,
                                                  _this.location.z));
      _this.mesh.omega_entity = _this;
      _this.dispatchEvent({type: 'loaded_mesh', data: _this.mesh});
    });

    this.lamp = Omega.JumpGate.gfx.lamp.clone();
    this.lamp.run_effects = Omega.JumpGate.gfx.lamp.run_effects; /// XXX
    if(this.location) this.lamp.position.set(this.location.x, this.location.y, this.location.z);

    this.particles = Omega.JumpGate.gfx.particles.clone();
    if(this.location) this.particles.position.set(this.location.x - 30,
                                                  this.location.y - 25,
                                                  this.location.z + 75);

    // FIXME need to set radius
    this.selection_sphere = Omega.JumpGate.gfx.selection_sphere.clone();
    if(this.location) this.selection_sphere.position.set(this.location.x - 20,
                                                         this.location.y,
                                                         this.location.z)

    this.components = [this.mesh, this.lamp, this.particles, this.selection_sphere];
  },

  run_effects : function(){
    /// update lamp
    this.lamp.run_effects();

    /// update particles
    var plane    = Omega.JumpGate.gfx.particle_plane_size,
        lifespan = Omega.JumpGate.gfx.lifespan;

    var p = plane*plane;
    var not_moving = [];
    while(p--){
      var pv = this.particles.geometry.vertices[p]
      if(pv.moving){
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = 200;
          pv.moving = false;
        }
      }else{
        not_moving.push(pv);
      }
    }
    /// pick random particle to start moving
    var index = Math.floor(Math.random()*(not_moving.length-1));
    if(index != -1) not_moving[index].moving = true;
    this.particles.geometry.__dirtyVertices = true;
  }
};

THREE.EventDispatcher.prototype.apply( Omega.JumpGate.prototype );
