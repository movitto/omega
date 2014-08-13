/* Omega Ship Artillery Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/attack/launcher"

/// TODO track 'attacked_by' (array on entities in ship) in attack events ?

Omega.ShipArtillery = function(args){
  this.init_launcher(args);
};

Omega.ShipArtillery.prototype = {
  interval : 0.15,

  /// TODO from config
  offsets : [[50, 0, 0], [-50, 0, 0]],

  _next_offset : function(){
    if(typeof(this.current_offset) === "undefined" ||
       this.current_offset == this.offsets.length-1)
      this.current_offset = 0;
    else
      this.current_offset += 1;

    var offset  = this.offsets[this.current_offset];
    return new THREE.Vector3().set(offset[0], offset[1], offset[2]);
  },

  clone : function(){
    return new Omega.ShipArtillery({template : this.template.clone()});
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

Omega.ShipArtillery.prototype.__init_projectile =
  Omega.ShipArtillery.prototype._init_projectile;

/// Override projectile initialization to set cycled offset
Omega.ShipArtillery.prototype._init_projectile = function(){
  var projectile = this.__init_projectile();
  var offset = this._next_offset();
  offset.applyMatrix4(this.omega_entity.location.rotation_matrix());
  projectile.location.add(offset);
  return projectile;
};
