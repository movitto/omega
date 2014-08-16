/* Omega JS Canvas Base Particles Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// Subclasses should implement
/// - _particle_group defining group
/// - _particle_emitter defining emitter
Omega.UI.BaseParticles = {
  _num_emitters : function(){
    return typeof(this.num_emitters) !== "undefined" ? this.num_emitters : 1;
  },

  init_particles : function(event_cb){
    var group   = this._particle_group(event_cb);

    for(var e = 0; e < this._num_emitters(); e++){
      var emitter = this._particle_emitter(e);
      group.addEmitter(emitter);
    }

    this.particles = group;
    this.clock = new THREE.Clock();
  },

  component : function(){
    return this.particles.mesh;
  },

  set_position : function(position){
    this.particles.mesh.position = position;
  },

  set_velocity : function(dx, dy, dz){
    for(var e = 0; e < this._num_emitters(); e++)
      this.particles.emitters[e].velocity.set(dx, dy, dz);
  },

  alive : function(){
    return !!(this.particles.emitters[0].alive);
  },

  enable : function(){
    for(var e = 0; e < this._num_emitters(); e++)
      this.particles.emitters[e].alive = true;
  },

  _stop_all_emitters : function(){
    for(var e = 0; e < this._num_emitters(); e++){
      this.particles.emitters[e].alive = false;
      this.particles.emitters[e].reset();
    }
  },

  disable : function(){
    this._stop_all_emitters();
  },

  run_effects : function(){
    this.particles.tick(this.clock.getDelta());
  }
};
