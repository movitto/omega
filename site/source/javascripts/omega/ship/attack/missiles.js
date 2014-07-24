/* Omega Ship Missiles Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/particles/targeted"

/// TODO track 'attacked_by' (array on entities in ship) in attack events,
/// update target_loc upon defender movement / remove here

Omega.ShipMissiles = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];
  this.init_particles(config, event_cb);
};

Omega.ShipMissiles.prototype = {
  particle_age         : 2,
  particle_count       : 1,
  particle_size        : 30,

  _particle_group : function(config, event_cb){
    return new SPE.Group({
      texture:    Omega.load_ship_particles(config, event_cb),
      maxAge:     this.particle_age,
      blending:   THREE.AdditiveBlending
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      colorStart    : new THREE.Color(0x0000FF),
      colorEnd      : new THREE.Color(0x0000FF),
      sizeStart     : this.particle_size,
      sizeEnd       : this.particle_size,
      opacityStart  : 0.75,
      opacityEnd    : 0.75,
      velocity      : new THREE.Vector3(0, 0, 1),
      particleCount : this.particle_count,
      alive         : 0
    });
  },

  clone : function(config, event_cb){
    return new Omega.ShipMissiles({config: config, event_cb: event_cb});
  },

  target : function(){
    return this.omega_entity.attacking;
  }
};

$.extend(Omega.ShipMissiles.prototype, Omega.UI.TargetedParticles.prototype);
