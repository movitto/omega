/* Omega Ship Destruction Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO add debris

Omega.ShipDestructionEffect = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];

  this.init_gfx(config, event_cb);
};

Omega.ShipDestructionEffect.prototype = {
  /// XXX since mesh is rotated by 1.57 around x below,
  /// need to reverse rotation in emitter position to
  /// compensate for the world rotation
  _rotation : function(){
    if(this.__rotation) return this.__rotation;
    var euler  = new THREE.Euler(-1.57, 0, 0);
    this.__rotation = new THREE.Matrix4();
    this.__rotation.makeRotationFromEuler(euler);
    return this.__rotation;
  },

  update : function(){
    var entity   = this.omega_entity;
    var loc      = entity.location;
    var rotation = this._rotation();

    var emitters = this.particles.emitters;
    for(var e = 0; e < emitters.length; e++){
      emitters[e].position.set(loc.x, loc.y, loc.z);
      Omega.rotate_position(emitters[e], rotation)
    }
  },

  _explosion_emitter : function(){
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
      colorStart:       new THREE.Color(0xCC6600),
      colorStartSpread: new THREE.Vector3(0, 0.33, 0),
      colorEnd:         new THREE.Color(0x996633),
      particleCount:     150,
      duration:         0.05,
      alive:               0,
    });
  },

  _shockwave_emitter : function(){
    return new ShaderParticleEmitter({
      type :           'disk',
      position: new THREE.Vector3(0, 0, 0),
      radius:               5,
      //radiusSpread:       5,
      radiusScale:         10,
      speed:               65,
      colorStart: new THREE.Color(0xFFCC33),
      colorEnd:   new THREE.Color(0xFFFF99),
      size:               100,
      sizeEnd:             50,
      opacityStart:         1,
      opacityEnd:           0,
      particlesPerSecond: 150,
      alive:                0
    });
  },

  _particle_group : function(config, event_cb){
    var particle_texture =
      Omega.load_ship_particles(config, event_cb, 'destruction');

    return new ShaderParticleGroup({
        texture:  particle_texture,
        maxAge:   5,
        blending: THREE.AdditiveBlending
      });
  },


  init_gfx : function(config, event_cb){
    this.particles = this._particle_group(config, event_cb);
    this.particles.addEmitter(this._explosion_emitter());
    this.particles.addEmitter(this._shockwave_emitter());
    this.particles.mesh.rotation.x = 1.57;

    /// used to update particle effects
    this.particle_clock = new THREE.Clock();
  },

  clone : function(config, event_cb){
    return new Omega.ShipDestructionEffect({config: config, event_cb: event_cb});
  },

  run_effects : function(){
    this.particles.tick(this.particle_clock.getDelta());
  },

  trigger : function(seconds, cb){
    var emitters = this.particles.emitters;
    for(var e = 0; e < emitters.length; e++)
      emitters[e].alive = true;

    var _this = this;
    $.timer(function(){
      for(var e = 0; e < emitters.length; e++){
        emitters[e].alive = false;
        emitters[e].reset();
      }

      this.stop();
      if(cb) cb();
    }, seconds, true);
  }
}
