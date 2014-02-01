/* Omega Ship Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/particles"
//= require "omega/ship/mesh"
//= require "omega/ship/highlight"
//= require "omega/ship/lamps"
//= require "omega/ship/trails"
//= require "omega/ship/attack_vector"
//= require "omega/ship/mining_vector"
//= require "omega/ship/trajectory"
//= require "omega/ship/hp_bar"
//= require "omega/ship/destruction"

/// TODO implement this mixin pattern in other js entities

// Ship GFX Mixin
Omega.ShipGfx = {
  debug_gfx : true,

  /// template mesh, mesh, and particle texture
  async_gfx : 3,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Ship.gfx)            === 'undefined') Omega.Ship.gfx = {};
    if(typeof(Omega.Ship.gfx[this.type]) !== 'undefined') return;

    var gfx              = {};
    Omega.Ship.gfx[this.type] = gfx;
    gfx.mesh_material    = new Omega.ShipMeshMaterial(config, this.type, event_cb);
    gfx.highlight        = new Omega.ShipHighlightEffects();
    gfx.lamps            = new Omega.ShipLamps(config, this.type);
    gfx.trails           = new Omega.ShipTrails(config, this.type, event_cb);
    gfx.attack_vector    = new Omega.ShipAttackVector(config, event_cb);
    gfx.mining_vector    = new Omega.ShipMiningVector();
    gfx.trajectory1      = new Omega.ShipTrajectory(0x0000FF);
    gfx.trajectory2      = new Omega.ShipTrajectory(0x00FF00);
    gfx.hp_bar           = new Omega.ShipHpBar();
    gfx.destruction      = new Omega.ShipDestructionEffect(config, event_cb);

    Omega.ShipMesh.load_template(config, this.type, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);

    this.components = [];

    var _this = this;
    Omega.ShipMesh.load(this.type, function(mesh){
      /// FIXME set emissive if ship is selected upon init_gfx
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.components.push(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
    });

    /// TODO change highlight mesh material if ship doesn't belong to user
    this.highlight = Omega.Ship.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;
    this.components.push(this.highlight.mesh);

    this.lamps = Omega.Ship.gfx[this.type].lamps.clone();
    this.lamps.omega_entity = this;
    for(var l = 0; l < this.lamps.olamps.length; l++){
      this.lamps.olamps[l].init_gfx();
      this.components.push(this.lamps.olamps[l].component);
    }

    this.trails = Omega.Ship.gfx[this.type].trails.clone();
    this.trails.omega_entity = this;
    for(var t = 0; t < this.trails.length; t++)
      this.components.push(this.trails.otrails[t])

    this.attack_vector = Omega.Ship.gfx[this.type].attack_vector.clone();
    this.attack_vector.omega_entity = this;

    this.mining_vector = Omega.Ship.gfx[this.type].mining_vector.clone();
    this.mining_vector.omega_entity = this;

    this.trajectory1   = Omega.Ship.gfx[this.type].trajectory1.clone();
    this.trajectory1.omega_entity = this;

    this.trajectory2   = Omega.Ship.gfx[this.type].trajectory2.clone();
    this.trajectory2.omega_entity = this;

    if(this.debug_gfx){
      this.components.push(this.trajectory1.mesh);
      this.components.push(this.trajectory2.mesh);
    }

    this.hp_bar = Omega.Ship.gfx[this.type].hp_bar.clone();
    this.hp_bar.omega_entity = this;
    this.hp_bar.bar.init_gfx(config, event_cb);
    for(var c = 0; c < this.hp_bar.bar.components.length; c++)
      this.components.push(this.hp_bar.bar.components[c]);

    /// central destruction particle emitter bound to this instance
    this.destruction = Omega.Ship.gfx[this.type].destruction.for_ship(this);
    this.destruction.omega_entity = this;

    this.update_gfx();
  },

  cp_gfx : function(from){
    /// return if not initialized
    if(!from.components || from.components.length == 0) return;
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
    to.destruction       = from.destruction;
  },

  update_gfx : function(){
    if(!this.location) return;
    if(this.mesh)          this.mesh.update();
    if(this.highlight)     this.highlight.update();
    if(this.lamps)         this.lamps.update();
    if(this.trails)        this.trails.update();
    if(this.trajectory1)   this.trajectory1.update('primary');
    if(this.trajectory2)   this.trajectory2.update('secondary');
    if(this.hp_bar)        this.hp_bar.update();
    if(this.attack_vector) this.attack_vector.update();
    if(this.mining_vector) this.mining_vector.update();

    this._update_location_state();
    this._update_command_state();
  },

  _has_trails : function(){
    return this.trails.otrails &&
           this.components.indexOf(this.trails.otrails[0]) != -1;
  },

  _add_trails : function(){
    for(var t = 0; t < this.trails.otrails.length; t++){
      var trail = this.trails.otrails[t];
      this.components.push(trail);
    }
  },

  _rm_trails : function(){
    for(var t = 0; t < this.trails.otrails.length; t++){
      var i = this.components.indexOf(this.trails.otrails[t]);
      this.components.splice(i, 1);
    }
  },

  _update_location_state : function(){
    /// add/remove trails based on movement strategy
    if(!this.location || !this.location.movement_strategy ||
       !this.trails   ||  this.trails.otrails.length == 0) return;
    var stopped = "Motel::MovementStrategies::Stopped";
    var is_stopped = this.location.is_stopped();
    var has_trails = this._has_trails();

    if(!is_stopped && !has_trails)
      this._add_trails();

    else if(is_stopped && has_trails)
      this._rm_trails();
  },

  _has_attack_vector : function(){
    return this.components.indexOf(this.attack_vector.vector) != -1;
  },

  _add_attack_vector : function(){
    this.components.push(this.attack_vector.vector);
  },

  _rm_attack_vector : function(){
    var i = this.components.indexOf(this.attack_vector.vector);
    this.components.splice(i, 1);
  },

  _has_mining_vector : function(){
    return this.components.indexOf(this.mining_vector.vector) != -1;
  },

  _add_mining_vector : function(){
   this.components.push(this.mining_vector.vector);
  },

  _rm_mining_vector : function(){
    var i = this.components.indexOf(this.mining_vector.vector);
    this.components.splice(i, 1);
  },

  _update_command_state : function(){
    if(!this.attack_vector || !this.mining_vector) return;

    /// add/remove attack vector depending on ship state
    var has_attack_vector = this._has_attack_vector();
    if(this.attacking){
      this.attack_vector.set_target(this.attacking);

      /// add attack vector if not in scene components
      if(!has_attack_vector) this._add_attack_vector();

    }else if(has_attack_vector){
      this._rm_attack_vector();
    }

    /// add/remove mining vector depending on ship state
    var has_mining_vector = this._has_mining_vector();
    if(this.mining && this.mining_asteroid){
      this.mining_vector.set_target(this.mining_asteroid);

      /// add mining vector if not in scene components
      if(!has_mining_vector) this._add_mining_vector();
        
    }else if(has_mining_vector){
      this._rm_mining_vector();
    }
  },

  ///////////////////////////////////////////////// effects

  _run_movement_effects : function(){
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

    if(!this.location.is_stopped()) this.last_moved = now;
  },

  run_effects : function(){
    this.lamps.run_effects();
    this.trails.run_effects();
    this._run_movement_effects();

    if(this.attacking) this.attack_vector.run_effects();

    this.destruction.run_effects();
  },

  trigger_destruction : function(destruction_cb){
    this.destruction.trigger(function(){
      /// TODO remove destruction particles from components?
      if(destruction_cb) destruction_cb();
    });
    this.components.push(this.destruction.particles.mesh);
  }
}
