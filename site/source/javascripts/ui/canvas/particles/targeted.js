/* Omega JS Canvas Targeted Particles Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/has_target"

Omega.UI.TargetedParticles = function(){};

Omega.UI.TargetedParticles.prototype = {
  update_target_loc : function(){
    this.target_loc(this.target().scene_location());

    var dist = this.get_distance();
    var speed = dist/this.particle_age;
    var dir  = this.get_direction();
    var dx = speed * dir[0]; var dy = speed * dir[1]; var dz = speed * dir[2];
    this.set_velocity(dx, dy, dz);
  }
};

$.extend(Omega.UI.TargetedParticles.prototype, Omega.UI.HasTarget.prototype);
