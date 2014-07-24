/* Omega JS Canvas Targeted Particles Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/has_target"

Omega.UI.TargetedParticles = function(){};

/// Subclasses should implement
/// - _particle_group defining group
/// - _particle_emitter defining emitter
Omega.UI.TargetedParticles.prototype = {
  init_particles : function(config, event_cb){
    this.clear_target_update();

    var group   = this._particle_group(config, event_cb);
    var emitter = this._particle_emitter();
    group.addEmitter(emitter);
    this.particles = group;
    this.clock = new THREE.Clock();
  },

  set_position : function(position){
    this.particles.mesh.position = position;
  },

  set_velocity : function(dist, dx, dy, dz){
    var vel = dist/this.particle_age;
    dx *= vel; dy *= vel; dz *= vel;
    this.particles.emitters[0].velocity.set(dx, dy, dz);
  },

  update_target_loc : function(){
    this.target_loc(this.target().scene_location());

    /// TODO incorporate new_loc's movement trajectory into this
    /// (eg shoot 'ahead' of ship)
    var dist = this.get_distance();
    var dir  = this.get_direction();
    var dx = dir[0]; var dy = dir[1]; var dz = dir[2];
    this.set_velocity(dist, dx, dy, dz);
  },

  alive : function(){
    return !!(this.particles.emitters[0].alive);
  },

  enable : function(){
    this.particles.emitters[0].alive = true;
  },

  disable : function(){
    this.particles.emitters[0].alive = false;
    this.particles.emitters[0].reset();
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};

$.extend(Omega.UI.TargetedParticles.prototype, Omega.UI.HasTarget.prototype);
