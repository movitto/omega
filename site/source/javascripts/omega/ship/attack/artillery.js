/* Omega Ship Artillery Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/particles/base"
//= require "ui/canvas/particles/targeted"
//= require "ui/canvas/particles/staggered"

/// TODO track 'attacked_by' (array on entities in ship) in attack events ?

Omega.ShipArtillery = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];

  this.disable_target_update();
  this.init_particles(config, event_cb);
};

Omega.ShipArtillery.prototype = {
  num_emitters         : 2,
  emitter_interval     : 0.75,
  particle_age         : 1,
  particle_count       : 5,
  particle_size        : 30,

  interval : function(){
    return this.particle_age / this.num_emitters;
  },

  _particle_group : function(config, event_cb){
    return new SPE.Group({
      texture:    Omega.load_ship_particles(config, event_cb, 'artillery'),
      maxAge:     this.particle_age,
      blending:   THREE.AdditiveBlending,
    });
  },

  _particle_emitter : function(config, event_cb, num){
    var position = num == 0 ? 20 : -20;

    return new SPE.Emitter({
      colorStart    : new THREE.Color(0xFFCC00),
      colorEnd      : new THREE.Color(0xFFCC00),
      sizeStart     : this.particle_size,
      sizeEnd       : this.particle_size,
      position      : new THREE.Vector3(position, 0, 0),
      opacityStart  : 0.75,
      opacityEnd    : 0.75,
      angleAlignVelocity : true,
      velocity      : new THREE.Vector3(0, 0, 1),
      particleCount : this.particle_count,
      alive         : 0
    });
  },

  clone : function(config, event_cb){
    return new Omega.ShipArtillery({config: config, event_cb: event_cb});
  },

  target : function(){
    return this.omega_entity.attacking;
  }
};

$.extend(Omega.ShipArtillery.prototype, Omega.UI.BaseParticles.prototype);
$.extend(Omega.ShipArtillery.prototype, Omega.UI.TargetedParticles.prototype);
$.extend(Omega.ShipArtillery.prototype, Omega.UI.StaggeredParticles.prototype);
