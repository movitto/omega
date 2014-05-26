/* Omega Solar System Particles
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemParticles = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];

  if(config) this.init_particles(config, event_cb);
};

Omega.SolarSystemParticles.prototype = {
  plane    :           100,
  lifespan :             5,
  velocity :            50,

  _texture : function(config, event_cb){
    var particle_path = config.url_prefix + config.images_path + "/particle.png";
    return THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
  },

  _group : function(texture){
    return new SPE.Group({
      texture  :  texture,
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

  init_particles : function(config, event_cb){
    this.particles = this._group(this._texture(config, event_cb));
    this.particles.addEmitter(this._emitter());

    this.clock = new THREE.Clock();
  },

  components : function(){
    return [this.particles.mesh];
  },

  clone : function(config, event_cb){
    return new Omega.SolarSystemParticles({config: config, event_cb: event_cb});
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
