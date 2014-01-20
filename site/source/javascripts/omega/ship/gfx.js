/* Omega Ship Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_ship_gfx = function(config, type, event_cb){
  var gfx = {};
  Omega.Ship.gfx[type] = gfx;

  gfx.mesh_material = new Omega.ShipMeshMaterial(config, type, event_cb);

  Omega.load_ship_template_mesh(config, type, function(mesh){
    gfx.mesh = mesh;
    Omega.Ship.prototype.loaded_resource('template_mesh_' + type, mesh);
    if(event_cb) event_cb();
  });

  gfx.highlight     = new Omega.ShipHighlightEffects();
  gfx.lamps         = Omega.load_ship_lamps(config, type);
  gfx.trails        = Omega.load_ship_trails(config, type, event_cb);
  gfx.attack_vector = new Omega.ShipAttackVector(config, event_cb);
  gfx.mining_vector = new Omega.ShipMiningVector();
  gfx.trajectory1   = new Omega.ShipTrajectory(0x0000FF);
  gfx.trajectory2   = new Omega.ShipTrajectory(0x00FF00);
  gfx.hp_bar        = new Omega.ShipHpBar();
};

Omega.init_ship_gfx = function(config, ship, event_cb){
  ship.components = [];

  Omega.load_ship_mesh(ship.type, function(mesh){
    /// FIXME set emissive if ship is selected upon init_gfx
    ship.mesh = mesh;
    ship.mesh.omega_entity = ship;
    ship.components.push(ship.mesh);
    ship.update_gfx();
    ship.loaded_resource('mesh', ship.mesh);
  });

  ship.highlight = Omega.Ship.gfx[ship.type].highlight.clone();
  ship.highlight.omega_entity = ship;
  ship.components.push(ship.highlight); /// TODO change highlight mesh material 
                                        /// if ship doesn't belong to user

  ship.lamps = [];
  for(var l = 0; l < Omega.Ship.gfx[ship.type].lamps.length; l++){
    var template_lamp = Omega.Ship.gfx[ship.type].lamps[l];
    var lamp = template_lamp.clone();
    lamp.init_gfx();
    ship.lamps.push(lamp);
    ship.components.push(lamp.component);
  }

  ship.trails = [];
  for(var t = 0; t < Omega.Ship.gfx[ship.type].trails.length; t++){
    var template_trail = Omega.Ship.gfx[ship.type].trails[t];
    var trail = template_trail.clone();
    trail.base_position = template_trail.base_position;
    ship.trails.push(trail);
  }

  ship.attack_vector = Omega.Ship.gfx[ship.type].attack_vector.clone();
  ship.mining_vector = Omega.Ship.gfx[ship.type].mining_vector.clone();
  ship.trajectory1   = Omega.Ship.gfx[ship.type].trajectory1.clone();
  ship.trajectory2   = Omega.Ship.gfx[ship.type].trajectory2.clone();

  if(ship.debug_gfx){
    ship.components.push(ship.trajectory1);
    ship.components.push(ship.trajectory2);
  }

  ship.hp_bar = Omega.Ship.gfx[ship.type].hp_bar.clone();
  ship.hp_bar.init_gfx(config, event_cb);
  for(var c = 0; c < ship.hp_bar.components.length; c++)
    ship.components.push(ship.hp_bar.components[c]);

  ship.update_gfx();
}

Omega.cp_ship_gfx = function(from, to){
  to.components        = from.components;
  to.shader_components = from.shader_components;
  to.mesh              = from.mesh;
  to.highlight         = from.highlight;
  to.lamps             = from.lamps;
  to.trails            = from.trails;
  to.attack_vector     = from.attack_vector;
  to.mining_vector     = from.mining_vector;
  to.trajectory1       = from.trajectory1;
  to.trajectory2       = from.trajectory2;
  to.hp_bar            = from.hp_bar;
}

Omega.update_ship_gfx = function(ship){
  /// TODO remove components if hp == 0
  ship._update_mesh();
  ship._update_highlight_effects();
  ship._update_lamps();
  ship._update_trails();
  ship._update_trajectories();
  ship._update_hp_bar();
  ship._update_command_vectors();
  ship._update_location_state();
  ship._update_command_state();
}

///////////////////////////////////////// initializers

Omega.load_ship_particles = function(config, event_cb){
  var particle_path     = config.url_prefix + config.images_path + '/particle.png';
  return THREE.ImageUtils.loadTexture(particle_path, {}, event_cb);
};

Omega.ShipMeshMaterial = function(config, type, event_cb){
  var texture_path    = config.url_prefix + config.images_path +
                        config.resources.ships[type].material;
  var texture         = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
  $.extend(this, new THREE.MeshLambertMaterial({map: texture, overdraw: true}));
};

Omega.load_ship_template_mesh = function(config, type, cb){
  var geometry_path   = config.url_prefix + config.images_path +
                        config.resources.ships[type].geometry;
  var geometry_prefix = config.url_prefix + config.images_path +
                        config.meshes_path;
  var rotation        = config.resources.ships[type].rotation;
  var offset          = config.resources.ships[type].offset;
  var scale           = config.resources.ships[type].scale;

  Omega.UI.Loader.json().load(geometry_path, function(mesh_geometry){
    var material = Omega.Ship.gfx[type].mesh_material;
    var mesh = new THREE.Mesh(mesh_geometry, material);
    mesh.base_position = mesh.base_rotation = [0,0,0];
    if(offset){
      mesh.position.set(offset[0], offset[1], offset[2]);
      mesh.base_position = offset;
    }
    if(scale)
      mesh.scale.set(scale[0], scale[1], scale[2]);
    if(rotation){
      mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
      mesh.matrix.makeRotationFromEuler(mesh.rotation);
      mesh.base_rotation = rotation;
    }
    cb(mesh);
  }, geometry_prefix);
};

Omega.load_ship_mesh = function(type, cb){
  Omega.Ship.prototype.retrieve_resource('template_mesh_' + type,
    function(template_mesh){
      var mesh = template_mesh.clone();

      /// so mesh materials can be independently updated:
      mesh.material = Omega.Ship.gfx[type].mesh_material.clone();

      /// copy custom attrs required later
      mesh.base_position = template_mesh.base_position;
      mesh.base_rotation = template_mesh.base_rotation;
      if(!mesh.base_position) mesh.base_position = [0,0,0];
      if(!mesh.base_rotation) mesh.base_rotation = [0,0,0];

      cb(mesh);
    });
};


Omega.ShipHighlightEffects = function(){
  var highlight_props    = Omega.Ship.prototype.highlight_props;
  var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
  var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                         shading: THREE.FlatShading } );
  var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
  highlight_mesh.position.set(highlight_props.x,
                              highlight_props.y,
                              highlight_props.z);
  highlight_mesh.rotation.set(highlight_props.rot_x,
                              highlight_props.rot_y,
                              highlight_props.rot_z);
  $.extend(this, highlight_mesh);
};

Omega.load_ship_lamps = function(config, type){
  var lamps  = config.resources.ships[type].lamps;
  var olamps = [];
  if(lamps){
    for(var l = 0; l < lamps.length; l++){
      var lamp  = lamps[l];
      var olamp = new Omega.UI.CanvasLamp({size : lamp[0],
                                           color: lamp[1],
                                   base_position: lamp[2]});
      olamps.push(olamp);
    }
  }

  return olamps;
};

Omega.load_ship_trails = function(config, type, event_cb){
  var trails = config.resources.ships[type].trails;
  var otrails = [];
  if(trails){
    var trail_props      = Omega.Ship.prototype.trail_props;
    var particle_texture = Omega.load_ship_particles(config, event_cb)

    var trail_material = new THREE.ParticleBasicMaterial({
      color: 0xFFFFFF, size: 20, map: particle_texture,
      blending: THREE.AdditiveBlending, transparent: true });

    for(var l = 0; l < trails.length; l++){
      var trail = trails[l];
      var geo   = new THREE.Geometry();

      var plane    = trail_props.plane;
      var lifespan = trail_props.lifespan;
      for(var i = 0; i < plane; ++i){
        for(var j = 0; j < plane; ++j){
          var pv = new THREE.Vector3(i, j, 0);
          pv.velocity = Math.random();
          pv.lifespan = Math.random() * lifespan;
          if(i >= plane / 4 && i <= 3 * plane / 4 &&
             j >= plane / 4 && j <= 3 * plane / 4 ){
               pv.lifespan *= 2;
               pv.velocity *= 2;
          }
          pv.olifespan = pv.lifespan;
          geo.vertices.push(pv)
        }
      }

      var otrail = new THREE.ParticleSystem(geo, trail_material);
      otrail.position.set(trail[0], trail[1], trail[2]);
      otrail.base_position = trail;
      otrail.sortParticles = true;
      otrails.push(otrail);
    }
  }
  return otrails;
};

Omega.ShipAttackVector = function(config, event_cb){
  var num_vertices = 20;
  var particle_texture = Omega.load_ship_particles(config, event_cb)
  var attack_material = new THREE.ParticleBasicMaterial({
    color: 0xFF0000, size: 20, map: particle_texture,
    blending: THREE.AdditiveBlending, transparent: true });
  var attack_geo = new THREE.Geometry();
  for(var v = 0; v < num_vertices; v++)
    attack_geo.vertices.push(new THREE.Vector3(0,0,0));
  var attack_vector = new THREE.ParticleSystem(attack_geo, attack_material);
  attack_vector.sortParticles = true;

  $.extend(this, attack_vector);
};

Omega.ShipMiningVector = function(){
  var mining_material = new THREE.LineBasicMaterial({color: 0x0000FF});
  var mining_geo      = new THREE.Geometry();
  mining_geo.vertices.push(new THREE.Vector3(0,0,0));
  mining_geo.vertices.push(new THREE.Vector3(0,0,0));
  var mining_vector   = new THREE.Line(mining_geo, mining_material);
  $.extend(this, mining_vector);
};

Omega.ShipTrajectory = function(color){
  var trajectory_mat = new THREE.LineBasicMaterial({color : color});
  var trajectory_geo = new THREE.Geometry();
  trajectory_geo.vertices.push(new THREE.Vector3(0,0,0));
  trajectory_geo.vertices.push(new THREE.Vector3(0,0,0));
  var trajectory = new THREE.Line(trajectory_geo, trajectory_mat);
  $.extend(this, trajectory);
};

Omega.ShipHpBar = function(){
  var len = Omega.Ship.prototype.health_bar_props.length;
  var bar =
    new Omega.UI.CanvasProgressBar({
      width : 3, length: len, axis : 'x',
      color1: 0xFF0000, color2: 0x0000FF,
      vertices: [[[-len/2, 100, 0],
                  [-len/2, 100, 0]],
                 [[-len/2, 100, 0],
                  [ len/2, 100, 0]]]});
  $.extend(this, bar);
};

///////////////////////////////////////// update methods

/// This module gets mixed into Ship
Omega.ShipGfxUpdaters = {
  _update_mesh : function(){
    if(!this.mesh) return;

    /// update mesh position and orientation
    this.mesh.position.set(this.location.x, this.location.y, this.location.z);
    this.mesh.position.add(new THREE.Vector3(this.mesh.base_position[0],
                                             this.mesh.base_position[1],
                                             this.mesh.base_position[2]));
    Omega.set_rotation(this.mesh, this.mesh.base_rotation);
    Omega.set_rotation(this.mesh, this.location.rotation_matrix());
  },

  _update_highlight_effects : function(){
    if(!this.highlight) return;

    /// update highlight effects position
    this.highlight.position.set(this.location.x,
                                this.location.y,
                                this.location.z);
    this.highlight.position.add(new THREE.Vector3(this.highlight_props.x,
                                                  this.highlight_props.y,
                                                  this.highlight_props.z));
  },

  _update_lamps : function(){
    if(!this.lamps) return;
    var _this = this;

    /// update lamps position
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.set_position(this.location.x, this.location.y, this.location.z);
      Omega.temp_translate(lamp.component, this.location, function(tlamp){
        Omega.rotate_position(tlamp, _this.location.rotation_matrix());
      });
    }
  },

  _update_trails : function(){
    if(!this.trails) return;
    var _this = this;

    /// update trails position and orientation
    for(var t = 0; t < this.trails.length; t++){
      var trail = this.trails[t];
      trail.position.set(this.location.x, this.location.y, this.location.z);
      trail.position.add(new THREE.Vector3(trail.base_position[0],
                                           trail.base_position[1],
                                           trail.base_position[2]));
      if(this.mesh){
        Omega.set_rotation(trail, this.mesh.base_rotation);
      }
      Omega.set_rotation(trail, this.location.rotation_matrix());
      Omega.temp_translate(trail, this.location, function(ttrail){
        Omega.rotate_position(ttrail, _this.location.rotation_matrix());
      });
    }
  },

  _update_trajectories : function(){
    if(!this.trajectory1 || !this.trajectory2) return;

    var loc = this.location;
    var orientation = loc.orientation();

    this.trajectory1.position.set(loc.x, loc.y, loc.z);
    this.trajectory2.position.set(loc.x, loc.y, loc.z);

    var t1v0 = this.trajectory1.geometry.vertices[0];
    var t1v1 = this.trajectory1.geometry.vertices[1];
    t1v0.set(0, 0, 0);
    t1v1.set(orientation[0] * 100,
             orientation[1] * 100,
             orientation[2] * 100);

    var t2v0 = this.trajectory2.geometry.vertices[0];
    var t2v1 = this.trajectory2.geometry.vertices[1];
    t2v0.set(0, 0, 0);
    t2v1.set(0, 50, 0);
    Omega.rotate_position(t2v1, loc.rotation_matrix());

    this.trajectory1.geometry.verticesNeedUpdate = true;
    this.trajectory2.geometry.verticesNeedUpdate = true;
  },

  _update_hp_bar : function(){
    if(!this.hp_bar) return;
    this.hp_bar.update(this.location, this.hp/this.max_hp);
  },

  _update_command_vectors : function(){
    if(!this.attack_vector || !this.mining_vector) return;

    /// update attack vector position
    this.attack_vector.position.set(this.location.x, this.location.y, this.location.z);

    /// update mining vector position
    this.mining_vector.position.set(this.location.x, this.location.y, this.location.z);
  },

  _update_location_state : function(){
    /// add/remove trails based on movement strategy
    if(!this.location || !this.location.movement_strategy ||
       !this.trails   ||  this.trails.length == 0) return;
    var stopped = "Motel::MovementStrategies::Stopped";
    var is_stopped = (this.location.movement_strategy.json_class == stopped);
    var has_trails = (this.components.indexOf(this.trails[0]) != -1);

    if(!is_stopped && !has_trails){
      for(var t = 0; t < this.trails.length; t++){
        var trail = this.trails[t];
        this.components.push(trail);
      }

    }else if(is_stopped && has_trails){
      for(var t = 0; t < this.trails.length; t++){
        var i = this.components.indexOf(this.trails[t]);
        this.components.splice(i, 1);
      }
    }
  },

  _update_command_state : function(){
    if(!this.attack_vector || !this.mining_vector) return;

    /// add/remove attack vector depending on ship state
    var has_attack_vector = this.components.indexOf(this.attack_vector) != -1;
    if(this.attacking){
      /// update attack vector properties
      var dist = this.location.distance_from(this.attacking.location.x,
                                             this.attacking.location.y,
                                             this.attacking.location.z);

      /// should be signed to preserve direction
      var dx = this.attacking.location.x - this.location.x;
      var dy = this.attacking.location.y - this.location.y;
      var dz = this.attacking.location.z - this.location.z;

      /// 5 unit particle + 55 unit spacer
      this.attack_vector.scalex = 60 / dist * dx;
      this.attack_vector.scaley = 60 / dist * dy;
      this.attack_vector.scalez = 60 / dist * dz;

      /// add attack vector if not in scene components
      if(!has_attack_vector) this.components.push(this.attack_vector);

    }else if(has_attack_vector){
      var i = this.components.indexOf(this.attack_vector);
      this.components.splice(i, 1);
    }

    /// add/remove mining vector depending on ship state
    var has_mining_vector = this.components.indexOf(this.mining_vector) != -1;
    if(this.mining && this.mining_asteroid){
      /// should be signed to preserve direction
      var dx = this.mining_asteroid.location.x - this.location.x;
      var dy = this.mining_asteroid.location.y - this.location.y;
      var dz = this.mining_asteroid.location.z - this.location.z;

      // update mining vector vertices
      this.mining_vector.geometry.vertices[0].set(0,0,0);
      this.mining_vector.geometry.vertices[1].set(dx,dy,dz);

      /// add mining vector if not in scene components
      if(!has_mining_vector) this.components.push(this.mining_vector);
        
    }else if(has_mining_vector){
      var i = this.components.indexOf(this.mining_vector);
      this.components.splice(i, 1);
    }
  }
}

///////////////////////////////////////// other

/// Also gets mixed into the Ship Module
Omega.ShipEffectRunner = {
  run_effects : function(){
    // animate lamps
    for(var l = 0; l < this.lamps.length; l++){
      var lamp = this.lamps[l];
      lamp.run_effects();
    }

    // animate trails
    var plane    = this.trail_props.plane,
        lifespan = this.trail_props.lifespan;
    for(var t = 0; t < this.trails.length; t++){
      var trail = this.trails[t];
      var p = plane*plane;
      while(p--){
        var pv = trail.geometry.vertices[p]
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = pv.olifespan;
        }
      }
      trail.geometry.verticesNeedUpdate = true;
    }

    /// move ship according to movement strategy to smoothen out movement animation
    var stopped = 'Motel::MovementStrategies::Stopped';
    var linear  = 'Motel::MovementStrategies::Linear';
    var rotate  = 'Motel::MovementStrategies::Rotate';
    var now     = new Date();
    if(this.last_moved != null){
      var elapsed = now - this.last_moved;

      if(this.location.movement_strategy.json_class == linear){
        var dist = this.location.movement_strategy.speed * elapsed / 1000;
        this.location.x += this.location.movement_strategy.dx * dist;
        this.location.y += this.location.movement_strategy.dy * dist;
        this.location.z += this.location.movement_strategy.dz * dist;
        this.update_gfx();

      }else if(this.location.movement_strategy.json_class == rotate){
        var dist = this.location.movement_strategy.rot_theta * elapsed / 1000;
        var new_or = Omega.Math.rot(this.location.orientation_x,
                                    this.location.orientation_y,
                                    this.location.orientation_z,
                                    dist,
                                    this.location.movement_strategy.rot_x,
                                    this.location.movement_strategy.rot_y,
                                    this.location.movement_strategy.rot_z);
        this.location.orientation_x = new_or[0];
        this.location.orientation_y = new_or[1];
        this.location.orientation_z = new_or[2];
        this.update_gfx();
      }
    }

    if(this.location.movement_strategy.json_class != stopped)
      this.last_moved = now;

    /// animate attack particles
    if(this.attacking){
      for(var p = 0; p < this.attack_vector.geometry.vertices.length; p++){
        var vertex = this.attack_vector.geometry.vertices[p];
        if(Math.floor( Math.random() * 20 ) == 1)
          vertex.moving = true;
        if(vertex.moving)
          vertex.add(new THREE.Vector3(this.attack_vector.scalex,
                                       this.attack_vector.scaley,
                                       this.attack_vector.scalez));

        var vertex_dist = 
          this.attacking.location.distance_from(this.location.x + vertex.x,
                                                this.location.y + vertex.y,
                                                this.location.z + vertex.z);

        /// FIXME if attack_vector.scale is large enough so that each
        /// hop exceeds 60, this check may be missed alltogether &
        /// particle will contiue to infinity
        if(vertex_dist < 60){
          vertex.set(0,0,0);
          vertex.moving = false;
        }
      }
      this.attack_vector.geometry.verticesNeedUpdate = true;
    }
  }
}
