/* Omega Ship Explosion Effect
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

/// Explosion Effect is applied to Ship's target, the entity which it is
/// attacking upon attack mechanisms (artillery, missiles) arrival
Omega.ShipExplosionEffect = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_gfx(event_cb);
  this._run_effects = this._no_trigger_effect;

  this.auto_trigger = false;
};

Omega.ShipExplosionEffect.prototype = {
  default_interval : 5,

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
      particleCount:     100,
      alive:               0,
      duration:         0.05
    };
  },

  update_state : function(){
    var entity = this.omega_entity;

    if(entity.attacking && this.auto_trigger)
      this._run_effects = this._trigger_effect;
    else
      this._run_effects = this._no_trigger_effect;
  },

  _particle_group : function(event_cb){
    var particle_texture = Omega.UI.Particles.load('ship.explosion', event_cb);
    return new SPE.Group({
        texture  : particle_texture,
        maxAge   : 0.5,
        blending : THREE.AdditiveBlending
      });
  },

  init_gfx : function(event_cb){
    this.particles = this._particle_group(event_cb);
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

  _interval : function(){
    return this.interval || this.default_interval;
  },

  /// Default pos is rand distance within certain max area around target ship
  _trigger_position : function(){
    var loc = this.omega_entity.attacking.scene_location();

    var area = 50; // TODO parameterize size
    var px = loc.x + (area * Math.random() - (area/2));
    var py = loc.y + (area * Math.random() - (area/2));
    var pz = loc.z + (area * Math.random() - (area/2));
    return new THREE.Vector3(px, py, pz);
  },

  _trigger_effect : function(){
   /// TODO could be potentially furthur optimized by scheduling
   /// tigger_effect to be run at specified interval async instead
   /// of relying on this conditional here
   if(this.clock.getElapsedTime() < this._interval()) return;

    /// reset clock
    this.clock = new THREE.Clock();

    this.trigger();
  },

  _no_trigger_effect : function(){
    /// intentionally empty (see update above)
  },

  /// manually trigger effect
  trigger : function(position){
    this.particles.triggerPoolEmitter(1, position || this._trigger_position());
  },

  run_effects : function(){
    this.particles.tick(this.particle_clock.getDelta());
    this._run_effects();
  }
}
