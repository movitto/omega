/* Omega Jump Gate Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO use particle emitter

Omega.JumpGateParticles = function(config, event_cb){
  if(config && event_cb)
    this.particle_system = this.init_gfx(config, event_cb);
};

Omega.JumpGateParticles.prototype = {
  clone : function(){
    var jgp = new Omega.JumpGateParticles();
    jgp.particle_system = this.particle_system.clone();
    return jgp;
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;

    this.particle_system.position.
      set(loc.x + Omega.JumpGateGfx.gfx_props.particles_x,
          loc.y + Omega.JumpGateGfx.gfx_props.particles_y,
          loc.z + Omega.JumpGateGfx.gfx_props.particles_z);
  },

  _material : function(config, event_cb){
    var gfx_props = Omega.JumpGateGfx.gfx_props;
    var particle_path = config.url_prefix + config.images_path + "/particle.png";
    var texture       = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
    var lifespan      = gfx_props.particle_life;
    return new THREE.ParticleBasicMaterial({
        color: 0x0000FF, size        : 20, depthWrite: false,
        map  : texture,  transparent : true,
        blending: THREE.AdditiveBlending
      });
  },

  _geometry : function(){
    var gfx_props = Omega.JumpGateGfx.gfx_props;
    var lifespan  = gfx_props.particle_life;
    var plane     = gfx_props.particle_plane;

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
    return particles;
  },

  init_gfx : function(config, event_cb){
    var particle_system =
      new THREE.ParticleSystem(this._geometry(config, event_cb),
                               this._material(config, event_cb));
    particle_system.sortParticles = true;
    return particle_system;
  },

  run_effects : function(){
    /// update particles
    var plane    = Omega.JumpGateGfx.gfx_props.particle_plane,
        lifespan = Omega.JumpGateGfx.gfx_props.particle_life;

    var p = plane*plane;
    var not_moving = [];
    while(p--){
      var pv = this.particle_system.geometry.vertices[p]
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
    this.particle_system.geometry.__dirtyVertices = true;
  }
};
