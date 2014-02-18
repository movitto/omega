/* Omega Jump Gate Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateParticles = function(config, event_cb){
  if(config) this.init_particles(config, event_cb);
};

Omega.JumpGateParticles.prototype = {
  plane    :            10,
  lifespan :            20,
  velocity :           -15,
  offset   : [0, -15, 85],

  _particle_group : function(config, event_cb){
    var particle_path = config.url_prefix + config.images_path + "/particle.png";
    var texture       = THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);

    return new ShaderParticleGroup({
      texture:  texture,
      maxAge:   this.lifespan,
      blending: THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      positionSpread     : new THREE.Vector3(this.plane, this.plane, 0),
      colorStart         : new THREE.Color(0x0000FF),
      colorEnd           : new THREE.Color(0x0000FF),
      sizeStart          : 50,
      sizeEnd            : 50,
      opacityStart       : 1,
      opacityEnd         : 1,
      velocity           : new THREE.Vector3(0, 0, this.velocity),
      particlesPerSecond : 3,
      alive              : 1
    });
  },

  init_particles : function(config, event_cb){
    this.particles = this._particle_group(config, event_cb);
    this.particles.addEmitter(this._particle_emitter());
    this.clock = new THREE.Clock();
  },

  clone : function(config, event_cb){
    return new Omega.JumpGateParticles(config, event_cb);
  },

  update : function(){
    if(!this.particles) return;

    var entity = this.omega_entity;
    var loc    = entity.location;
    this.particles.emitters[0].position.
      set(loc.x + this.offset[0],
          loc.y + this.offset[1],
          loc.z + this.offset[2]);
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
