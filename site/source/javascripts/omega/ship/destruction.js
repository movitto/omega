/* Omega Ship Destruction Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipDestructionEffect = function(config, event_cb){
  this.init_gfx(config, event_cb);
};

Omega.ShipDestructionEffect.prototype = {
  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.particles.emitters[0].position.set(loc.x, loc.y, loc.z);
  },

  _particle_emitter : function(){
    return new ShaderParticleEmitter({
      type:             'sphere',
      positionSpread:   new THREE.Vector3(10, 10, 10),
      radius:              1,
      speed:             100,
      sizeStart:          30,
      sizeStartSpread:    30,
      sizeEnd:             0,
      opacityStart:        1,
      opacityEnd:          0,
      colorStart:       new THREE.Color('yellow'),
      colorStartSpread: new THREE.Vector3(0, 10, 0),
      colorEnd:         new THREE.Color('red'),
      particleCount:    1000,
      duration:         0.05,
      alive:               0
    });
  },

  _particle_group : function(config, event_cb){
    var particle_texture =
      Omega.load_ship_particles(config, event_cb, 'destruction');

    return new ShaderParticleGroup({
        texture:  particle_texture,
        maxAge:   2,
        blending: THREE.AdditiveBlending
      });
  },

  init_gfx : function(config, event_cb){
    this.particles = this._particle_group(config, event_cb);
    this.particles.addEmitter(this._particle_emitter());

    /// used to update particle effects
    this.particle_clock = new THREE.Clock();
  },

  clone : function(config, event_cb){
    return new Omega.ShipDestructionEffect(config, event_cb);
  },

  run_effects : function(){
    this.particles.tick(this.particle_clock.getDelta());
  },

  trigger : function(seconds, cb){
    this.particles.emitters[0].alive = true;

    var _this = this;
    $.timer(function(){
      _this.particles.emitters[0].alive = false;
      _this.particles.emitters[0].reset();
      this.stop();
      if(cb) cb();
    }, seconds, true);
  }
}
