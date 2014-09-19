/* Omega Ship Missile Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"
//= require "ui/canvas/components/particles/base"

//= require "omega/ship/attack/projectile"

Omega.ShipMissile = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_projectile(args);
  this.init_particles(event_cb);

  /// offset particles so they are emerging from end of missile, not middle
  this.particles.mesh.position.set(0, 0, -50);
  this.mesh.add(this.particles.mesh);
};

Omega.ShipMissile.prototype = {
  speed            : 1000000,
  acceleration     : 1000000,
  rot_theta        : 0.55,
  theta_tolerance  : Math.PI / 64,
  launch_distance  :  250,
  arrival_distance :   50,

  particle_age     :     1,

  _particle_group : function(event_cb){
    return new SPE.Group({
      maxAge   : this.particle_age,
      texture  : Omega.UI.Particles.load('ship.missile', event_cb)
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      alive           :    1,
      particleCount   :   25,
      sizeStart       :   75,
      sizeEnd         :    5,
      opacityStart    :    1,
      opacityEnd      :    1,
      colorStart      : new THREE.Color(0xAB0000),
      colorEnd        : new THREE.Color(0xFF0000),
      positionSpread  : new THREE.Vector3(0, 0, 1),
      velocity        : new THREE.Vector3(0, 0, -50)
    });
  },

  components : function(){
    return [this.mesh];
  },

  clone : function(){
    return new Omega.ShipMissile({mesh : this.mesh.clone()});
  },

  /// Perpendicular to original omega_entity orientation
  launch_dir : function(){
    if(this._launch_dir) return this._launch_dir;
    var rotation     = this.source.location.rotation_matrix();
    var dir          = Omega.Math.CARTESIAN_MINOR;
        dir          = new THREE.Vector3(dir[0], dir[1], dir[2]);
    this._launch_dir = Omega.rotate_position(dir, rotation);
    return this._launch_dir;
  },

  move_to_target : function(){
    var delta = this.clock.getDelta();
    this.particles.tick(delta);

    if(!this.launching()){
      if(!this.launched) this._mark_launched();
      this._face_target(delta);
    }

    this._move_linear(delta);
    this._update_component();
  }
};

$.extend(Omega.ShipMissile.prototype, Omega.ShipProjectile);
$.extend(Omega.ShipMissile.prototype, Omega.UI.BaseParticles);

Omega.ShipMissile.geometry_for = function(type, cb){
  var geometry_path   = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.resources.missile.geometry;
  var geometry_prefix = Omega.Config.url_prefix + Omega.Config.images_path +
                        Omega.Config.meshes_path;
  return [geometry_path, geometry_prefix];
};
