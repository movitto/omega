/* Omega Ship Trails Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

//= require "ui/canvas/components/particles/base"
//= require "ui/canvas/components/particles/updatable"

Omega.ShipTrails = function(args){
  if(!args) args = {};
  var type     = args['type'];
  var event_cb = args['event_cb'];

  this.type = type;
  this.disable_updates();
  this.load_config_particles();
  this.init_particles(event_cb);
};

Omega.ShipTrails.prototype = {
  lifespan             : 0.5,
  particle_speed       : 50,

  clone : function(){
    return new Omega.ShipTrails({type: this.type});
  },

  load_config_particles : function(){
    this.config_trails = Omega.Config.resources.ships[this.type].trails;
    if(!this.config_trails){
      this.num_emitters = 0;
      return;
    }
    this.config_trails = this.config_trails.slice(0);

    for(var t = 0; t < this.config_trails.length; t++){
      this.config_trails[t] = new THREE.Vector3(this.config_trails[t][0],
                                                this.config_trails[t][1],
                                                this.config_trails[t][2]);
    }
    this.num_emitters = this.config_trails.length;
  },

  _particle_group : function(event_cb){
    return new SPE.Group({
      maxAge   : this.lifespan,
      blending : THREE.AdditiveBlending,
      texture  : Omega.UI.Particles.load('ship.trails', event_cb)
    });
  },

  _particle_emitter : function(num){
    var position = this.config_trails[num];

    return new SPE.Emitter({
      position        : position,
      alive           :    0,
      particleCount   : 2000,
      sizeStart       :   30,
      sizeEnd         :   10,
      opacityStart    :    1,
      opacityEnd      :    0,
      colorStart      : new THREE.Color(0x000000),
      colorEnd        : new THREE.Color(0xFF0000),
      positionSpread  : new THREE.Vector3(0, 0, 1),
      velocity        : new THREE.Vector3(0, 0, -this.particle_speed)
    });
  },

  _update_emitters : function(){},

  enabled_state : function(){
    return this.num_emitters > 0 && !this.omega_entity.location.is_stopped()
  }
};

$.extend(Omega.ShipTrails.prototype, Omega.UI.BaseParticles.prototype);
$.extend(Omega.ShipTrails.prototype, Omega.UI.UpdatableParticles.prototype);
