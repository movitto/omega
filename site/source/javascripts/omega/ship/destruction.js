/* Omega Ship Destruction Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipDestructionEffect = function(config, event_cb){
  this.init_gfx(config, event_cb);
};

Omega.ShipDestructionEffect.prototype = {
  init_gfx : function(config, event_cb){
    var particle_texture =
      Omega.load_ship_particles(config, event_cb, 'destruction');

    var emitterSettings = {
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

    this.particles =
      new ShaderParticleGroup({
        texture:  particle_texture,
        maxAge:   0.5,
        blending: THREE.AdditiveBlending
      });

    /// TODO make sure to add enough emitters to pool to
    this.particles.addPool(500, emitterSettings, false);

    /// used to update particle effects
    this.particle_clock = new THREE.Clock();
  },

  /// Return this destruction effect instance w/ additional per-ship metadata
  for_ship : function(ship){
    var ndestruct   = $.extend({}, this);

    /// used to track when to emit new explosions
    ndestruct.clock = new THREE.Clock();

    return ndestruct;
  },

  run_effects : function(){
    this.particles.tick(this.particle_clock.getDelta());

    var entity = this.omega_entity;
    var loc    = entity.location;
    if(!this.being_destroyed) return;

    if(this.elapsed_effect * 1000 < 750){
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
    this.ticks -= 1;
    if(this.ticks == 0){
      this.being_destroyed = false;
      if(this.cb) this.cb();
    }
  },

  trigger : function(destruction_cb){
    this.elapsed_effect  = 0;
    this.ticks           = 10;
    this.cb              = destruction_cb;
    this.being_destroyed = true;
  }
}
