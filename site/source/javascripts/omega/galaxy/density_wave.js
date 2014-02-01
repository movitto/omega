/* Omega Galaxy Density Wave
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/particles"

Omega.GalaxyDensityWave = function(config, event_cb){
  this.particles = this.init_gfx(config, event_cb);
};

Omega.GalaxyDensityWave.prototype = {
  _particle_group : function(config, event_cb){
    return new ShaderParticleGroup({
      texture: Omega.load_galaxy_particles(config, event_cb),
      maxAge: 2,
      fadeFactor :  7500.0,
      blending: THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      type           : 'spiral',
      spiralSkew     : 1.4,
      spiralRotation : 1.4,
      position     : new THREE.Vector3(0, 0, 0),
      radius       : 1000,
      radiusSpread : 2000,
      radiusScale  :  150,
      speed        :  50,
      colorStart   : new THREE.Color('yellow'),
      colorEnd     : new THREE.Color('white'),
      size         : 1000,
      //sizeSpread : 1,
      sizeEnd      : 100,
      opacityStart : 1,
      opacityEnd   : 0,
      particlesPerSecond: 5000,
    });
  },

  init_gfx : function(config, event_cb){
    var group   = this._particle_group(config, event_cb);
    var emitter = this._particle_emitter();
    group.addEmitter(emitter);
    return group;
  }
};
