/* Omega Ship Destruction Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO add debris

//= require "ui/particles"

Omega.ShipDestructionEffect = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_gfx(event_cb);
};

Omega.ShipDestructionEffect.prototype = {
  set_position : function(position){
    this.particles.mesh.position = position;
  },

  _explosion_emitter : function(){
    return new SPE.Emitter({
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
    return new SPE.Emitter({
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

  _particle_group : function(event_cb){
    var particle_texture = Omega.UI.Particles.load('ship.destruction', event_cb);

    return new SPE.Group({
        texture  : particle_texture,
        maxAge   : 5,
        blending : THREE.AdditiveBlending
      });
  },


  init_gfx : function(event_cb){
    this.particles = this._particle_group(event_cb);
    this.particles.addEmitter(this._explosion_emitter());
    this.particles.addEmitter(this._shockwave_emitter());
    this.particles.mesh.rotation.x = 1.57;

    /// used to update particle effects
    this.particle_clock = new THREE.Clock();
  },

  clone : function(){
    return new Omega.ShipDestructionEffect();
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
