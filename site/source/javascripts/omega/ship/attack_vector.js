/* Omega Ship Attack Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipAttackVector = function(config, event_cb){
  this.init_gfx(config, event_cb);
};

Omega.ShipAttackVector.prototype = {
  particle_age         : 2,
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
      particlesPerSecond : this.particles_per_second,
      alive         : 0
    });
  },

  init_gfx : function(config, event_cb){
    var group   = this._particle_group(config, event_cb);
    var emitter = this._particle_emitter();
    group.addEmitter(emitter);
    this.particles = group;
    this.clock = new THREE.Clock();
  },

  clone : function(config, event_cb){
    return new Omega.ShipAttackVector(config, event_cb);
  },

  update : function(){
    var loc = this.omega_entity.location;
    this.particles.emitters[0].position.set(loc.x, loc.y, loc.z);
  },

  target : function(){
    return this.omega_entity.attacking;
  },

  has_target : function(){
    return !!(this.target());
  },

  target_loc : function(new_loc){
    if(new_loc){
      this._target_loc = new_loc.clone();

      var loc  = this.omega_entity.location;
      var dist = loc.distance_from(new_loc.x, new_loc.y, new_loc.z);
      var vel  = dist/this.particle_age;
      var dx   = (new_loc.x - loc.x) / dist * vel;
      var dy   = (new_loc.y - loc.y) / dist * vel;
      var dz   = (new_loc.z - loc.z) / dist * vel;
      /// TODO incorporate new_loc's movement trajectory into this
      /// (eg shoot 'ahead' of ship)

      this.particles.emitters[0].velocity.set(dx, dy, dz);
    }

    return this._target_loc;
  },

  has_target_loc : function(){
    return !!(this.target_loc());
  },

  target_loc_needs_update : function(){
    var tolerance = 5; // TODO configurable ?
    var target = this.target();
    var tl     = this.target_loc();
    if(!this.has_target_loc()) return true;

    var different_target = target.location.id != tl.id;
    var exceeds_tolerance =
      (target.location.distance_from(tl.x, tl.y, tl.z) > tolerance);

    return different_target || exceeds_tolerance;
  },

  update_target_loc : function(){
    this.target_loc(this.target().location);
  },

  alive : function(){
    return !!(this.particles.emitters[0].alive);
  },

  enable : function(){
    this.particles.emitters[0].alive = true;
  },

  disable : function(){
    this.particles.emitters[0].alive = false;
    this.particles.emitters[0].reset();
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());

    if(this.has_target()){
      this.enable();
      if(this.target_loc_needs_update())
        this.update_target_loc();
    }else{
      this.disable();
    }
  }
};
