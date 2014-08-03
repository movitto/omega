/* Omega Solar System Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

Omega.SolarSystemParticles = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_particles(event_cb);
};

Omega.SolarSystemParticles.prototype = {
  plane    :           100,
  lifespan :             5,
  velocity :            50,

  _group : function(event_cb){
    return new SPE.Group({
      texture  :  Omega.UI.Particles.load('solar_system', event_cb),
      maxAge   :  this.lifespan,
      blending :  THREE.AdditiveBlending
    });
  },

  _emitter : function(){
    return new SPE.Emitter({
      positionSpread     : new THREE.Vector3(this.plane, 0, this.plane),
      colorStart         : new THREE.Color(0x00FFFF),
      colorEnd           : new THREE.Color(0x00FFFF),
      sizeStart          : 150,
      sizeEnd            : 150,
      opacityStart       : 1,
      opacityEnd         : 0,
      velocity           : new THREE.Vector3(0, this.velocity, 0),
      particleCount      : 10,
      alive              : 1
    });
  },

  init_particles : function(event_cb){
    this.particles = this._group(event_cb);
    this.particles.addEmitter(this._emitter());

    this.clock = new THREE.Clock();
  },

  components : function(){
    return [this.particles.mesh];
  },

  clone : function(){
    return new Omega.SolarSystemParticles();
  },

  update : function(){
    if(!this.particles) return;

    var loc = this.omega_entity.scene_location();
    this.particles.emitters[0].position.set(loc.x, loc.y, loc.z);
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
