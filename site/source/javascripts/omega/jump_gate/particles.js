/* Omega Jump Gate Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

Omega.JumpGateParticles = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_particles(event_cb);
};

Omega.JumpGateParticles.prototype = {
  plane    :         10,
  lifespan :         20,
  velocity :        -15,
  offset   : [0, 0, 75],

  _particle_group : function(event_cb){
    return new SPE.Group({
      texture  : Omega.UI.Particles.load('jump_gate', event_cb),
      maxAge   : this.lifespan,
      blending : THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      positionSpread     : new THREE.Vector3(this.plane, this.plane, 0),
      colorStart         : new THREE.Color(0x0000FF),
      colorEnd           : new THREE.Color(0x0000FF),
      sizeStart          : 50,
      sizeEnd            : 50,
      opacityStart       : 1,
      opacityEnd         : 0,
      velocity           : new THREE.Vector3(0, 0, this.velocity),
      particlesPerSecond : 3,
      alive              : 1
    });
  },

  init_particles : function(event_cb){
    this.particles = this._particle_group(event_cb);
    this.particles.addEmitter(this._particle_emitter());
    this.clock = new THREE.Clock();
  },

  clone : function(){
    return new Omega.JumpGateParticles();
  },

  update : function(){
    if(!this.particles) return;

    var loc = this.omega_entity.scene_location();
    this.particles.emitters[0].position.
      set(loc.x + this.offset[0],
          loc.y + this.offset[1],
          loc.z + this.offset[2]);
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
