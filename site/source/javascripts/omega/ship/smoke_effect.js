/* Omega Ship Smoke Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipSmokeEffect = function(config, event_cb){
  this.init_gfx(config, event_cb);
};

Omega.ShipSmokeEffect.prototype = {
  plane    :  15,
  velocity :  50,
  pps      :  150,
  lifespan :   1,

  _emitter : function(){
    return this.particles.emitters[0];
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;

    var rand = Math.random() * 25;
    this._emitter().position.set(loc.x + rand, loc.y + 10, loc.z + rand);
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      positionSpread     : new THREE.Vector3(this.plane, 0, this.plane),
      colorStart         : new THREE.Color(0x663300),
      colorEnd           : new THREE.Color(0x666666),
      sizeStart          :   20,
      sizeEnd            :   20,
      opacityStart       : 0.75,
      opacityEnd         : 0.75,
      velocity           : new THREE.Vector3(0, this.velocity, 0),
      particlesPerSecond :  this.pps,
      alive              :    0,
    });
  },

  _particle_group : function(config, event_cb){
    var particle_texture = Omega.load_ship_particles(config, event_cb, 'smoke');

    return new ShaderParticleGroup({
        texture:  particle_texture,
        maxAge:   this.lifespan,
        blending: THREE.AdditiveBlending
      });
  },

  init_gfx : function(config, event_cb){
    this.particles = this._particle_group(config, event_cb);
    this.particles.addEmitter(this._particle_emitter());
    this.clock = new THREE.Clock();
  },

  clone : function(config, event_cb){
    return new Omega.ShipSmokeEffect(config, event_cb);
  },

  enable : function(){
    this._emitter().alive = true;
  },

  disable : function(){
    this._emitter().alive = false;
    this._emitter().reset();
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());

    if(this.omega_entity.hpp() < 0.5)
      this.enable();
    else
      this.disable();
  }
}
