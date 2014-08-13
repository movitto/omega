/* Omega Ship Missiles Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/attack/launcher"

Omega.ShipMissiles = function(args){
  this.init_launcher(args);
}

Omega.ShipMissiles.prototype = {
  interval : 10,

  clone : function(){
    return new Omega.ShipMissiles({template : this.template.clone()});
  },

  should_explode : function(projectile){
    /// always explode on removal
    return true;
  },

  should_remove : function(projectile){
    return !this.target() || projectile.near_target();
  }
}

$.extend(Omega.ShipMissiles.prototype, Omega.ShipAttackLauncher);
