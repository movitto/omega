/* Omega Ship Explosion Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/// TODO look into better way to synchronize w/ attack particles
/// perhaps hook registered w/ attack particle emitter which is
/// invoked upon particle retirement

Omega.ShipExplosionEffect = function(config, event_cb){
  this.init_gfx(config, event_cb);
};

Omega.ShipExplosionEffect.prototype = {
  /// TODO make sure to add enough emitters to pool to cover all ships
  num_emitters : 500,

  _emitter_settings : function(){
    return {
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
      alive:               0,
      duration:         0.05
    };
  },

  _particle_group : function(config, event_cb){
    var particle_texture =
      Omega.load_ship_particles(config, event_cb, 'explosion');

    return new ShaderParticleGroup({
        texture:  particle_texture,
        maxAge:   0.5,
        blending: THREE.AdditiveBlending
      });
  },

  init_gfx : function(config, event_cb){
    this.particles = this._particle_group(config, event_cb);
    this.particles.addPool(this.num_emitters, this._emitter_settings(), false);

    /// used to update particle effects
    this.particle_clock = new THREE.Clock();
  },

  /// Return this exlosion effect instance w/ additional per-ship metadata
  for_ship : function(ship){
    var nexplosion = $.extend({}, this);

    /// used to track when to emit new explosions
    nexplosion.clock = new THREE.Clock();

    return nexplosion;
  },

  run_effects : function(){
    this.particles.tick(this.particle_clock.getDelta());

    var entity = this.omega_entity;
    if(!entity.attacking){
      this.started_at = null;
      return;
    }

    /// we delay until first particle arrives
    var interval = Omega.ShipAttackVector.prototype.particle_age * 1000;
    if(!this.started_at) this.started_at = new Date();
    if(new Date() - this.started_at < interval) return;
       
    var loc = entity.attacking.location;

    /// synchronize to attack vector particle emission
    if(this.elapsed_effect * 1000 < interval){
      this.elapsed_effect += this.clock.getDelta();
      return;
    }

    // rand distance within certain max area around ship
    var area = 50; // TODO parameterize size
    var px = loc.x + (area * Math.random() - (area/2));
    var py = loc.y + (area * Math.random() - (area/2));
    var pz = loc.z + (area * Math.random() - (area/2));
    var current_pos = new THREE.Vector3(px, py, pz);
    this.particles.triggerPoolEmitter(1, current_pos);

    this.elapsed_effect = 0;
  }
}
