/* Omega Ship Missile Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO missile rockets & trails

//= require "ui/canvas/has_target"

Omega.ShipMissile = function(args){
  if(!args) args = {};
  var mesh = args['mesh'];

  this.mesh     = mesh;
  this.location = new Omega.Location({movement_strategy : { distance : this.arrival_distance}});
  this.clock    = new THREE.Clock();
};

Omega.ShipMissile.prototype = {
  speed           : 500000,
  rot_theta       : 0.35,
  theta_tolerance : Math.PI / 32,
  launch_distance :  500,
  arrival_distance:   50,

  component : function(){
    return this.mesh;
  },

  clone : function(config, event_cb){
    return new Omega.ShipMissile({mesh : this.mesh.clone()});
  },

  set_source : function(source){
    this.source = source;
    this.location.set(source.location);
    this.location.set_orientation(this.launch_dir());
  },

  set_target : function(target){
    this.target = target;
    this.location.set_tracking(target.scene_location());
  },

  near_target : function(){
    return this.location.on_target();
  },

  launching : function(){
    return !this.launched &&
            this.location.distance_from(this.source.location) < this.launch_distance;
  },

  /// Perpendicular to original omega_entity orientation
  launch_dir : function(){
    if(this._launch_dir) return this._launch_dir;
    var rotation     = this.source.location.rotation_matrix();
    var dir          = Omega.Math.CARTESIAN_NORMAL;
        dir          = new THREE.Vector3(dir[0], dir[1], dir[2]);
    this._launch_dir = Omega.rotate_position(dir, rotation);
    return this._launch_dir;
  },

  explode : function(){
    this.source.explosions.trigger();
  },

  move_to_target : function(){
    var delta = this.clock.getDelta();
    if(!this.launching()){
      if(!this.launched) this.location.face_target();
      this.launched = true;

      var rot_angle = this.rot_theta * delta;
      if(!this.location.facing_target(this.theta_tolerance))
        this.location.rotate_orientation(rot_angle);
    }

    var distance = this.speed * delta / 1000;
    this.location.move_linear(distance);

    this.mesh.rotation.setFromRotationMatrix(this.location.rotation_matrix());
    this.mesh.position.set(this.location.x,
                           this.location.y,
                           this.location.z);
  }
};

/// Async template missile loader
Omega.ShipMissile.load_template = function(config, type, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.missile.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;

  Omega.UI.Loader.json().load(geometry_path, function(missile_geometry){
    var material = new THREE.MeshBasicMaterial({color : 0x000000});
    var mesh     = new THREE.Mesh(missile_geometry, material);
    var missile  = new Omega.ShipMissile({mesh : mesh});

    cb(missile);
    Omega.Ship.prototype.loaded_resource('template_missile_' + type, missile);
  }, geometry_prefix);
};

/// Async missile loader
Omega.ShipMissile.load = function(type, cb){
  Omega.Ship.prototype.retrieve_resource('template_missile_' + type,
    function(template_missile){
      var missile = template_missile.clone();
      cb(missile);
    });
};
