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
  _star_group : function(age, config, event_cb){
    return new SPE.Group({
      texture  : Omega.load_galaxy_particles(config, event_cb, 'stars'),
      maxAge   : age,
      blending : THREE.AdditiveBlending
    });
  },

  _cloud_group : function(config, event_cb){
    return new SPE.Group({
      texture  : Omega.load_galaxy_particles(config, event_cb, 'clouds'),
      maxAge   : 10,
      blending : THREE.AdditiveBlending
    });
  },

  _star_emitter : function(spiral, speed){
    return new SPE.Emitter({
      type           : 'spiral',
      spiralSkew     :  spiral,
      spiralRotation :  spiral,
      maxBuldge      :  5000000,
      position       : new THREE.Vector3(0, 0, 0),
      radius         :  3250,
      radiusSpread   :  5000,
      speed          : speed,
      colorStart     : new THREE.Color('yellow'),
      colorEnd       : new THREE.Color('white'),
      sizeStart      : 375.0,
      opacityStart   :     0,
      opacityMiddle  :     1,
      opacityEnd     :     0,
      particleCount  :   500
    });
  },

  _cloud_emitter : function(spiral){
    return new SPE.Emitter({
      type           : 'spiral',
      spiralSkew     :  spiral,
      spiralRotation :  spiral,
      radius         :    5000,
      radiusSpread   :    4000,
      speed          :      15,
      position       : new THREE.Vector3(0, 0, 0),
      positionSpread : new THREE.Vector3(5000, 0, 5000),
      colorStart     : new THREE.Color(0x3399FF),
      colorEnd       : new THREE.Color(0x33CCFF),
      sizeStart      :    4500,
      sizeSpread     :    1000,
      opacityStart   :       0,
      opacityMiddle  :    0.10,
      opacityEnd     :       0,
      particleCount  :     500
    });
  },

  _base_emitter : function(){
    return new SPE.Emitter({
      type           :  'disk',
      radius         :    4000,
      radiusSpread   :    6000,
      sizeStart      :    8000,
      sizeSpread     :    1000,
      opacityStart   :       0,
      opacityMiddle  :    0.05,
      opacityEnd     :       0,
      particleCount  :     500,
      position       : new THREE.Vector3(0, 0, 0),
      positionSpread : new THREE.Vector3(5000, 0, 5000),
      colorStart     : new THREE.Color(0x3399FF),
      colorEnd       : new THREE.Color(0x3366FF)
    });
  },

  init_gfx : function(config, event_cb){
    this.clock = new THREE.Clock();

    this.stars1  = this._star_group(2, config, event_cb);
    this.stars2  = this._star_group(4, config, event_cb);
    this.clouds1 = this._cloud_group(config, event_cb);
    this.clouds2 = this._cloud_group(config, event_cb);
    this.base    = this._cloud_group(config, event_cb);

    var semitter = this._star_emitter(1.4, 25);
    this.stars1.addEmitter(semitter);

    semitter = this._star_emitter(1.6, 40);
    this.stars2.addEmitter(semitter);

    semitter = this._star_emitter(1.8, 15);
    this.stars2.addEmitter(semitter);

    var cemitter = this._cloud_emitter(1.4);
    this.clouds1.addEmitter(cemitter);

    cemitter = this._cloud_emitter(1.6);
    this.clouds2.addEmitter(cemitter);

    var bemitter = this._base_emitter();
    this.base.addEmitter(bemitter);
  },

  set_rotation : function(x, y, z){
    this.stars1.mesh.rotation.set(x, y, z);
    this.stars2.mesh.rotation.set(x, y, z);
    this.clouds1.mesh.rotation.set(x, y, z);
    this.clouds2.mesh.rotation.set(x, y, z);
    this.base.mesh.rotation.set(x, y, z);
  },

  run_effects : function(){
    var delta = this.clock.getDelta();
    this.stars1.tick(delta);
    this.stars2.tick(delta);
    this.clouds1.tick(delta);
    this.clouds2.tick(delta);
    this.base.tick(delta);
  },

  components : function(){
    return [this.stars1.mesh,  this.stars2.mesh,
            this.clouds1.mesh, this.clouds2.mesh,
            this.base.mesh];
  }
};
