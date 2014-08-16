/* Omega Ship Shell Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/particles"
//= require "ui/canvas/components/particles/base"

//= require "omega/ship/attack/projectile"

Omega.ShipShellMaterial = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  /// TODO from config
  var texture_path = Omega.Config.url_prefix + Omega.Config.images_path + '/photon.png'
  var texture = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  this.material = new THREE.MeshBasicMaterial({map         : texture,
                                               side        : THREE.DoubleSide,
                                               transparent : true,
                                               color       : new THREE.Color(0xFFCC00)});
};

Omega.ShipShell = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];

  this.init_projectile(args);
  this.init_particles(event_cb);

  this.component = new THREE.Object3D();
  this.component.add(this.mesh);

  /// offset particles for better effect
  this.particles.mesh.position.set(0, 0, 10);
  this.component.add(this.particles.mesh);
};

Omega.ShipShell.prototype = {
  speed            : 2000000,
  rot_theta        :       0.45,
  launch_distance  :       0,
  arrival_distance :     150,

  _particle_group : function(event_cb){
    return new SPE.Group({
      blending : THREE.AdditiveBlending,
      texture  : Omega.UI.Particles.load('ship.artillery', event_cb),
      maxAge   : 1
    });
  },

  _particle_emitter : function(){
    return new SPE.Emitter({
      alive            :   1,
      particleCount    : 100,
      sizeStart        :  20,
      sizeEnd          :  20,
      opacityStart     :   1,
      opacityEnd       :   0,
      colorStart       : new THREE.Color(0xFFCC00),
      colorStartSpread : new THREE.Vector3(00, 66, 00),
      colorEnd         : new THREE.Color(0xFF6600),
      colorEndSpread   : new THREE.Vector3(00, 66, 00),
      velocity         : new THREE.Vector3(0, 0, -20)
    });
  },

  components : function(){
    return [this.component];
  },

  clone : function(){
    return new Omega.ShipShell({mesh : this.mesh.clone()});
  },

  launch_dir : function(){
    if(this._launch_dir) return this._launch_dir;
    this._launch_dir = this.location.direction_to_target();
    return this._launch_dir;
  },

  move_to_target : function(){
    var delta = this.clock.getDelta();
    this.particles.tick(delta);

    if(!this.launched) this._mark_launched();
    this._move_linear(delta);
    this._update_component();

    /// TODO billboard mesh
    /// http://nehe.gamedev.net/article/billboarding_how_to/18011/
    this.mesh.rotation.set(0, -1.57, 0);
  },

  exceeds_distance : function(){
    return this.location.distance_from(this.location.tracking) >= this.expected_distance * 2;
  },
};

$.extend(Omega.ShipShell.prototype, Omega.ShipProjectile);
$.extend(Omega.ShipShell.prototype, Omega.UI.BaseParticles);

Omega.ShipShell.prototype._set_source =
  Omega.ShipShell.prototype.set_source;

Omega.ShipShell.prototype.set_source = function(source){
  this._set_source(source);
  this.expected_distance = this.location.distance_from(this.location.tracking);
};

Omega.ShipShell.prototype._set_target =
  Omega.ShipShell.prototype.set_target;

Omega.ShipShell.prototype.set_target = function(target){
  if(this._target_set) return;
  this.target_set = true;
  this._set_target(target);
}

Omega.ShipShell.template = function(args){
  /// TODO configurable
  var size = 15;

  var material = args['material'];
  var geometry = new THREE.PlaneGeometry(size, size, 1, 1);
  return new Omega.ShipShell({material: material, geometry: geometry});
}
