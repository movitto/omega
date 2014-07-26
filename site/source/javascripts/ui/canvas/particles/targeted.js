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

    /// TODO incorporate new_loc's movement trajectory into this
    /// (eg shoot 'ahead' of ship)
    var dist = this.get_distance();
    var dir  = this.get_direction();
    var dx = dir[0]; var dy = dir[1]; var dz = dir[2];
    this.set_velocity(dist, dx, dy, dz);
  }
};

$.extend(Omega.UI.TargetedParticles.prototype, Omega.UI.HasTarget.prototype);
