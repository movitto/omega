/* Omega Ship Missiles Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/attack/launcher"

Omega.ShipMissiles = function(args){
  this.init_launcher(args);
  this.load_config(args);
}

Omega.ShipMissiles.prototype = {
  interval : 10,

  load_config : function(args){
    var type = args['type'];
    this.type = type;

    if(Omega.Config.resources.ships[type].missiles)
      this.offsets = Omega.Config.resources.ships[type].missiles;
  },

  clone : function(){
    return new Omega.ShipMissiles({type : this.type,
                                   template : this.template.clone()});
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
