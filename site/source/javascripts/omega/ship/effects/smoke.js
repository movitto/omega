/* Omega Ship Smoke Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

Omega.ShipSmokeEffect = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_gfx(event_cb);
};

Omega.ShipSmokeEffect.prototype = {
  plane    :  5,
  velocity :  5,
  count    :  500,
  lifespan :  5,

  _emitter : function(){
    return this.particles.emitters[0];
  },

  update_state : function(){
    var entity = this.omega_entity;

    if(entity.hpp() < 0.5)
      this.enable();
    else
      this.disable();
  },

  _particle_emitter : function(){
    var rand = Math.random() * 10;

    return new SPE.Emitter({
      position           : new THREE.Vector3(rand, rand, rand),
      positionSpread     : new THREE.Vector3(this.plane, 0, this.plane),
      colorStart         : new THREE.Color(0x666666),
      colorEnd           : new THREE.Color(0x663300),
      sizeStart          :   20,
      sizeEnd            :    1,
      opacityStart       : 0.75,
      opacityEnd         : 0.75,
      velocity           : new THREE.Vector3(0, this.velocity, 0),
      particleCount      :  this.count,
      alive              :    0,
    });
  },

  _particle_group : function(event_cb){
    var particle_texture = Omega.UI.Particles.load('ship.smoke', event_cb);

    return new SPE.Group({
      texture  : particle_texture,
      maxAge   : this.lifespan,
      blending : THREE.AdditiveBlending
    });
  },

  init_gfx : function(event_cb){
    this.particles = this._particle_group(event_cb);
    this.particles.addEmitter(this._particle_emitter());
    this.clock = new THREE.Clock();
  },

  clone : function(){
    return new Omega.ShipSmokeEffect();
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
