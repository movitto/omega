/* Omega Jump Gate Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_jump_gate_gfx = function(config, event_cb){
  var gfx = {};
  Omega.JumpGate.gfx = gfx;

  gfx.mesh_material = Omega.load_jump_gate_mesh_material(config, event_cb);

  Omega.load_jump_gate_template_mesh(config, function(mesh){
    gfx.mesh = mesh;
    Omega.JumpGate.prototype.loaded_resource('template_mesh', mesh);
    if(event_cb) event_cb();
  });

  gfx.lamp      = Omega.load_jump_gate_lamp(config, event_cb);
  gfx.particles = Omega.load_jump_gate_particles(config, event_cb);
  gfx.selection_sphere_material =
    Omega.load_jump_gate_sphere_material(config, event_cb);
};

Omega.init_jump_gate_gfx = function(config, jump_gate, event_cb){
  jump_gate.components = [];

  Omega.load_jump_gate_mesh(config, function(mesh){
    jump_gate.mesh = mesh;
    if(jump_gate.location)
      jump_gate.mesh.position.
        add(new THREE.Vector3(jump_gate.location.x,
                              jump_gate.location.y,
                              jump_gate.location.z));
    jump_gate.mesh.omega_entity = jump_gate;
    jump_gate.components.push(jump_gate.mesh);
    jump_gate.loaded_resource('mesh', jump_gate.mesh);
  });

  jump_gate.lamp = Omega.JumpGate.gfx.lamp.clone();
  if(jump_gate.location)
    jump_gate.lamp.set_position(jump_gate.location.x,
                                jump_gate.location.y,
                                jump_gate.location.z);
  jump_gate.lamp.init_gfx();
  jump_gate.components.push(jump_gate.lamp.component);

  var particles_offset = [jump_gate.gfx_props.particles_x,
                          jump_gate.gfx_props.particles_y,
                          jump_gate.gfx_props.particles_z];
  jump_gate.particles = Omega.JumpGate.gfx.particles.clone();
  if(jump_gate.location)
    jump_gate.particles.position.
      set(jump_gate.location.x + particles_offset[0],
          jump_gate.location.y + particles_offset[1],
          jump_gate.location.z + particles_offset[2]);
  jump_gate.components.push(jump_gate.particles);

  var segments = 32, rings = 32,
      material = Omega.JumpGate.gfx.selection_sphere_material;
  var geometry =
    new THREE.SphereGeometry(jump_gate.trigger_distance/2, segments, rings);
  jump_gate.selection_sphere = new THREE.Mesh(geometry, material);
  if(jump_gate.location)
    jump_gate.selection_sphere.position.
      set(jump_gate.location.x - 20,
          jump_gate.location.y,
          jump_gate.location.z)
};

///////////////////////////////////////// initializers

Omega.load_jump_gate_mesh_material = function(config, event_cb){
  var texture_path  = config.url_prefix + config.images_path +
                      config.resources.jump_gate.material;
  var texture       = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  texture.wrapS     = texture.wrapT    = THREE.RepeatWrapping;
  texture.repeat.x  = texture.repeat.y = 5;
  return new THREE.MeshLambertMaterial({ map: texture });
};

Omega.load_jump_gate_template_mesh = function(config, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.jump_gate.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.jump_gate.rotation;
  var offset          = config.resources.jump_gate.offset;
  var scale           = config.resources.jump_gate.scale;


  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.JumpGate.gfx.mesh_material;
    var mesh = new THREE.Mesh(mesh_geometry, material);
    if(offset){
      mesh.position.set(offset[0], offset[1], offset[2]);
      mesh.base_position = offset;
    }
    if(scale)
      mesh.scale.set(scale[0], scale[1], scale[2]);
    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
      mesh.base_rotation = rotation;
    }
    cb(mesh);
  }, geometry_prefix);
};

Omega.load_jump_gate_mesh = function(config, cb){
  Omega.JumpGate.prototype.retrieve_resource('template_mesh',
    function(template_mesh){
      var mesh = template_mesh.clone();
      cb(mesh);
    });
};

Omega.load_jump_gate_lamp = function(config, event_cb){
  var gfx_props = Omega.JumpGate.prototype.gfx_props;
  return new Omega.UI.CanvasLamp({size  : 10,
                                  color : 0xff0000,
             base_position : [gfx_props.lamp_x,
                              gfx_props.lamp_y,
                              gfx_props.lamp_z]});
};

Omega.load_jump_gate_particles = function(config, event_cb){
  var gfx_props = Omega.JumpGate.prototype.gfx_props;
  var particle_path = config.url_prefix + config.images_path + "/particle.png";
  var texture       = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
  var lifespan      = gfx_props.particle_life,
      plane         = gfx_props.particle_plane;
  var particles_material =
    new THREE.ParticleBasicMaterial({
      color: 0x0000FF, size        : 20, depthWrite: false,
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
  return particle_system;
};

Omega.load_jump_gate_sphere_material = function(config, event_cb){
  return new THREE.MeshBasicMaterial({color       : 0xffffff,
                                      transparent : true, depthWrite: false,
                                      opacity     : 0.1});
}

///////////////////////////////////////// other

/// Gets mixed into the JumpGate Module
Omega.JumpGateEffectRunner = {
  run_effects : function(){
    /// update lamp
    this.lamp.run_effects();

    /// update particles
    var plane    = this.gfx_props.particle_plane,
        lifespan = this.gfx_props.particle_life;

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
}
