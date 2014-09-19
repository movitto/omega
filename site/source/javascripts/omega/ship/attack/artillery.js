/* Omega Ship Artillery Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/attack/launcher"

/// TODO track 'attacked_by' (array on entities in ship) in attack events ?

Omega.ShipArtillery = function(args){
  this.init_launcher(args);
  this.load_config(args);
};

Omega.ShipArtillery.prototype = {
  interval : 0.15,

  load_config : function(args){
    var type = args['type'];
    this.type = type;

    if(Omega.Config.resources.ships[type].artillery)
      this.offsets = Omega.Config.resources.ships[type].artillery;
  },

  clone : function(){
    return new Omega.ShipArtillery({type : this.type,
                                    template : this.template.clone()});
  },

  should_explode : function(projectile){
    return this.has_target() && projectile.near_target();
  },

  should_remove : function(projectile){
    return (this.has_target() && projectile.near_target()) ||
            projectile.exceeds_distance();
  }
};

$.extend(Omega.ShipArtillery.prototype, Omega.ShipAttackLauncher);

Omega.ShipArtillery.prototype._should_launch =
  Omega.ShipArtillery.prototype.should_launch;

/// Override should_launch to only attack if facing target
Omega.ShipArtillery.prototype.should_launch = function(){
  var facing_target = !!(this.target()) &&
                      this.omega_entity.location.facing(this.target().location, Math.PI / 32);
  return this._should_launch() && facing_target;
};
