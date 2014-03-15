/* Omega Ship Smoke Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipSmokeEffect = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];

  this.init_gfx(config, event_cb);
  this._update = this._no_update;
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
    this._update();
  },

  update_state : function(){
    var entity = this.omega_entity;

    if(entity.hpp() < 0.5){
      this._update = this._update_emitter;
      this._update();
      this.enable();
    }else{
      this._update = this._no_update;
      this.disable();
    }
  },

  _no_update : function(){
  },

  _update_emitter : function(){
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
    return new Omega.ShipSmokeEffect({config: config, event_cb: event_cb});
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
  }
}
