/* Omega Ship Trails Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTrails = function(config, type, event_cb){
  if(config && type)
    this.init_particles(config, type, event_cb);
};

Omega.ShipTrails.prototype = {
  particles_per_second :  30,
  plane                :   5,
  lifespan             :   1,
  particle_speed       :   1,

  _particle_velocity : function(){
    if(this.__particle_velocity) return this.__particle_velocity;
    this.__particle_velocity = new THREE.Vector3(0, 0, -this.particle_speed);
    return this.__particle_velocity;
  },

  _particle_group : function(config, event_cb){
    return new ShaderParticleGroup({
      texture:    Omega.load_ship_particles(config, event_cb),
      maxAge:     this.lifespan,
      blending:   THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      positionSpread     : new THREE.Vector3(this.plane, this.plane, 0),
      colorStart         : new THREE.Color(0xFFFFFF),
      colorEnd           : new THREE.Color(0xFFFFFF),
      sizeStart          :   20,
      sizeEnd            :   20,
      opacityStart       :    1,
      opacityEnd         :    0,
      velocity           : this._particle_velocity(),
      particlesPerSecond : this.particles_per_second,
      alive              :    0,
    });
  },

  init_particles : function(config, type, event_cb){
    this.config_trails = config.resources.ships[type].trails;
    if(!this.config_trails) return null;

    this.clock     = new THREE.Clock();
    this.particles = this._particle_group(config, event_cb);

    for(var t = 0; t < this.config_trails.length; t++){
      /// replace config array w/ vector
      var config_trail = this.config_trails[t];
      if(config_trail.constructor != THREE.Vector3)
        this.config_trails[t] =
          new THREE.Vector3(config_trail[0], config_trail[1], config_trail[2]);

      /// create new emitter add to group
      var emitter = this._particle_emitter();
      this.particles.addEmitter(emitter);
    }
  },

  clone : function(config, type, event_cb){
    return new Omega.ShipTrails(config, type, event_cb);
  },

  _update_emitter : function(e){
    var entity        = this.omega_entity;
    var loc           = entity.location;
    var config_trail  = this.config_trails[e];
    var emitter       = this.particles.emitters[e];

    /// keep emitter position in sync w/ location
    emitter.position.set(loc.x, loc.y, loc.z);
    emitter.position.add(config_trail);
    Omega.temp_translate(emitter, loc, function(temitter){
      Omega.rotate_position(temitter, loc.rotation_matrix());
    });

    /// rotate emitter velocity to match location orientation
    emitter.velocity = this._particle_velocity();
    if(entity.mesh)
      Omega.set_emitter_velocity(emitter, entity.mesh.base_rotation);
    Omega.set_emitter_velocity(emitter, loc.rotation_matrix());
    emitter.velocity.multiplyScalar(this.particle_speed);
  },

  update : function(){
    if(!this.config_trails) return;

    if(this.omega_entity.location.is_stopped())
      this.disable();
    else{
      this.enable();
      for(var t = 0; t < this.config_trails.length; t++)
        this._update_emitter(t);
    }
  },

  enable : function(){
    for(var e = 0; e < this.particles.emitters.length; e++)
      this.particles.emitters[e].alive = true;
  },

  disable : function(){
    for(var e = 0; e < this.particles.emitters.length; e++){
      this.particles.emitters[e].alive = false;
      this.particles.emitters[e].reset();
    }
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
