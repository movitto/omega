/* Omega Ship Attack Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO explode particles on impact

Omega.ShipAttackVector = function(config, event_cb){
  this.init_gfx(config, event_cb);
};

Omega.ShipAttackVector.prototype = {
  particle_age         : 5,
  particles_per_second : 0.5,
  particle_size        : 30,

  _particle_group : function(config, event_cb){
    return new ShaderParticleGroup({
      texture:    Omega.load_ship_particles(config, event_cb),
      maxAge:     this.particle_age,
      fadeFactor: 7500.0,
      blending:   THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      colorStart    : new THREE.Color(0xFF0000),
      colorEnd      : new THREE.Color(0xFF0000),
      sizeStart     : this.particle_size,
      sizeEnd       : this.particle_size,
      opacityStart  : 0.75,
      opacityEnd    : 0.75,
      velocity      : new THREE.Vector3(0, 0, 1),
      particlesPerSecond : this.particles_per_second
    });
  },

  init_gfx : function(config, event_cb){
    /// TODO shared emitter & group for all ships?
    var group   = this._particle_group(config, event_cb);
    var emitter = this._particle_emitter();
    group.addEmitter(emitter);
    this.particles = group;
  },

  /// Return this destruction effect instance w/ additional per-ship metadata
  for_ship : function(ship){
    var nattack = $.extend({}, this);

    /// used to track when to emit new explosions
    nattack.clock = new THREE.Clock();

    return nattack;
  },

  update : function(){
    var loc = this.omega_entity.location;
    this.particles.emitters[0].position.set(loc.x, loc.y, loc.z);
  },

  set_target : function(target){
    var entity = this.omega_entity;
    var loc    = entity.location;
    var tloc   = target.location;
    this.target_location = tloc;

    var dist = loc.distance_from(tloc.x, tloc.y, tloc.z);
    var vel  = dist/this.particle_age;
    var dx   = (loc.x - tloc.x) / dist * vel;
    var dy   = (loc.y - tloc.y) / dist * vel;
    var dz   = (loc.z - tloc.z) / dist * vel;

    this.particles.emitters[0].velocity.set(dx, dy, dz);
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
