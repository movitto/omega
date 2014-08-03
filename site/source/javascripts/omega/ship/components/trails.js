/* Omega Ship Trails Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"

//= require "ui/canvas/particles/base"
//= require "ui/canvas/particles/updatable"

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
  lifespan             :     1,
  particle_speed       :     1,

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

  _particle_emitter : function(){
    return new SPE.Emitter({
      alive           :    0,
      particleCount   : 2000,
      sizeStart       :   40,
      sizeEnd         :    5,
      opacityStart    :    1,
      opacityEnd      :    0,
      colorStart      : new THREE.Color(0x000000),
      colorEnd        : new THREE.Color(0x00FFFF),
      positionSpread  : new THREE.Vector3(0, 0, 1),
      speed           : this.particle_speed,
      angleAlignVelocity : true
    });
  },

  _update_emitters : function(e){
    for(var t = 0; t < this._num_emitters(); t++)
      this._update_emitter(t);
  },

  /// keep emitter position in sync w/ location
  sync_emitter_position : function(e){
    var loc          = this.omega_entity.scene_location();
    var config_trail = this.config_trails[e];
    var emitter      = this.particles.emitters[e];

    emitter.position.set(loc.x, loc.y, loc.z);
    emitter.position.add(config_trail);
    Omega.temp_translate(emitter, loc, function(temitter){
      Omega.rotate_position(temitter, loc.rotation_matrix());
    });
  },

  /// rotate emitter velocity to match location orientation
  sync_emitter_orientation : function(e){
    var loc     = this.omega_entity.scene_location();
    var emitter = this.particles.emitters[e];

    Omega.set_emitter_velocity(emitter, loc.rotation_matrix());
    emitter.velocity.multiplyScalar(this.particle_speed);
  },

  _update_emitter : function(e){
    this.sync_emitter_position(e);
    this.sync_emitter_orientation(e);
  },

  enabled_state : function(){
    return this.num_emitters > 0 && !this.omega_entity.location.is_stopped()
  }
};

$.extend(Omega.ShipTrails.prototype, Omega.UI.BaseParticles.prototype);
$.extend(Omega.ShipTrails.prototype, Omega.UI.UpdatableParticles.prototype);
