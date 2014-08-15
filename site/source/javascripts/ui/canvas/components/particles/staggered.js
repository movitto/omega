/* Omega JS Canvas Stagerred Particles Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.UI.StaggeredParticles = function(){};

/// Subclasses should implement
/// - emitter_interval defining interval we should wait
///    between starting emitters
Omega.UI.StaggeredParticles.prototype = {
  enable : function(){
    var _this = this;
    this.enabled = 0;

    if(!this.particle_timer){
      this.particle_timer = $.timer(function(){
        if(_this.enabled == _this.particles.emitters.length) return;
        _this.particles.emitters[_this.enabled].alive = true;
        _this.enabled += 1;
      }, _this.emitter_interval * 1000, false);
    }

    this.particle_timer.play();
  },

  disable : function(){
    if(this.particle_timer)
      this.particle_timer.stop();
    this._stop_all_emitters();
  }
};
