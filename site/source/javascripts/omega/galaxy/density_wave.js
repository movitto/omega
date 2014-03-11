/* Omega Galaxy Density Wave
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/galaxy/particles"

Omega.GalaxyDensityWave = function(args){
  if(!args) args = {};
  config   = args['config'];
  event_cb = args['event_cb'];

  this.init_gfx(config, event_cb);
};

Omega.GalaxyDensityWave.prototype = {
  _star_group : function(config, event_cb){
    return new ShaderParticleGroup({
      texture: Omega.load_galaxy_particles(config, event_cb, 'stars'),
      maxAge: 2,
      blending: THREE.AdditiveBlending
    });
  },

  _cloud_group : function(config, event_cb){
    return new ShaderParticleGroup({
      texture: Omega.load_galaxy_particles(config, event_cb, 'clouds'),
      maxAge: 10,
      blending: THREE.AdditiveBlending
    });
  },

  _star_emitter : function(){
    return new ShaderParticleEmitter({
      type           : 'spiral',
      spiralSkew     : 1.4,
      spiralRotation : 1.4,
      position     : new THREE.Vector3(0, 0, 0),
      radius       : 1000,
      radiusSpread : 2000,
      radiusScale  :  150,
      speed        :  25,
      colorStart   : new THREE.Color('yellow'),
      colorEnd     : new THREE.Color('white'),
      sizeStart    : 75.0,
      //sizeStartSpread : 1,
      //sizeEnd      : 800,
      opacityStart  : 0,
      opacityMiddle : 1,
      opacityEnd    : 0,
      particlesPerSecond: 2500
    });
  },

  _cloud_emitter : function(){
    return new ShaderParticleEmitter({
      type           : 'spiral',
      spiralSkew     :  1.4,
      spiralRotation :  1.4,
      radius         : 1000,
      radiusSpread   : 2000,
      radiusScale    :  150,
      speed          :    5,
      position       : new THREE.Vector3(0, 0, 0),
      positionSpread : new THREE.Vector3(5000, 0, 5000),
      colorStart     : new THREE.Color('blue'),
      colorEnd       : new THREE.Color('white'),
      sizeStart      : 1250,
      sizeSpread     :  100,
      opacityStart   :    0,
      opacityMiddle  : 0.05,
      opacityEnd     :    0,
      particlesPerSecond : 200
    });
  },

  init_gfx : function(config, event_cb){
    var sgroup   = this._star_group(config, event_cb);
    var semitter = this._star_emitter();
    sgroup.addEmitter(semitter);
    this.stars = sgroup;

    var cgroup   = this._cloud_group(config, event_cb);
    var cemitter = this._cloud_emitter();
    cgroup.addEmitter(cemitter);
    this.clouds = cgroup;
  }
};
