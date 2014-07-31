/* Omega Ship Missile Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/has_target"

Omega.ShipMissile = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];
  var mesh     = args['mesh'];

  this.mesh     = mesh;
  this.location = new Omega.Location({movement_strategy : { distance : this.arrival_distance}});
  this.clock    = new THREE.Clock();
  this.init_particles(config, event_cb);
};

Omega.ShipMissile.prototype = {
  speed           : 300000,
  rot_theta       : 0.35,
  theta_tolerance : Math.PI / 32,
  launch_distance :  500,
  arrival_distance:   50,

  particle_age    :     1,
  particle_speed  :     1,

  components : function(){
    return [this.mesh, this.particles.mesh];
  },

  _particle_group : function(config, event_cb){
    return new SPE.Group({
      maxAge   : this.particle_age,
      texture  : Omega.load_ship_particles(config, event_cb, 'missile')
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
      speed           : this.particle_speed,
      angleAlignVelocity : true
    });
  },

  clone : function(config, event_cb){
    return new Omega.ShipMissile({config: config, event_cb : event_cb,
                                  mesh : this.mesh.clone()});
  },

  set_source : function(source){
    this.source = source;

    this.location.set(source.location);
    this.location.set_orientation(this.launch_dir());

    this.align_particles();
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

  align_particles : function(){
    var _this = this;

    /// offset particles so they are emerging from end of missile, not middle
    var offset = new THREE.Vector3(0, 0, -50);
        offset.applyMatrix4(this.location.rotation_matrix());

    this.particles.emitters[0].position.set(this.location.x + offset.x,
                                            this.location.y + offset.y,
                                            this.location.z + offset.z)
    this.set_velocity(this.particle_age, this.location.orientation_x,
                                         this.location.orientation_y,
                                         this.location.orientation_z);
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

    this.align_particles();
    this.particles.tick(delta);

    this.mesh.rotation.setFromRotationMatrix(this.location.rotation_matrix());
    this.mesh.position.set(this.location.x,
                           this.location.y,
                           this.location.z);
  }
};

$.extend(Omega.ShipMissile.prototype, Omega.UI.BaseParticles.prototype);

/// Async template missile loader
Omega.ShipMissile.load_template = function(config, type, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.missile.geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;

  Omega.UI.Loader.json().load(geometry_path, function(missile_geometry){
    var material = new THREE.MeshBasicMaterial({color : 0x000000});
    var mesh     = new THREE.Mesh(missile_geometry, material);
    var missile  = new Omega.ShipMissile({config: config, mesh : mesh});

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
