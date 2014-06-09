/* Omega Ship Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx"

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
//= require "omega/ship/destruction_audio"
//= require "omega/ship/explosion_effect"
//= require "omega/ship/smoke_effect"
//= require "omega/ship/mining_audio"
//= require "omega/ship/docking_audio"
//= require "omega/ship/combat_audio"
//= require "omega/ship/movement_audio"

// Ship GFX Mixin
Omega.ShipGfx = {
  debug_gfx : false,
  include_highlight : true,
  include_hp_bar    : true,

  /// template mesh, mesh, and particle texture
  async_gfx : 3,

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded(this.type)) return;
    Omega.Ship.gfx    = Omega.Ship.gfx || {};

    var gfx           =      {};
    gfx.hp_bar        =      new Omega.ShipHpBar();
    gfx.highlight     =      new Omega.ShipHighlightEffects();
    gfx.mesh_material =      new Omega.ShipMeshMaterial({config: config,
                                                           type: this.type,
                                                       event_cb: event_cb});
    gfx.lamps         =             new Omega.ShipLamps({config: config,
                                                           type: this.type});
    gfx.trails        =            new Omega.ShipTrails({config: config,
                                                           type: this.type,
                                                       event_cb: event_cb});
    gfx.attack_vector =      new Omega.ShipAttackVector({config: config,
                                                       event_cb: event_cb});
    gfx.mining_vector =      new Omega.ShipMiningVector({config: config,
                                                       event_cb: event_cb});
    gfx.trajectory1   =         new Omega.ShipTrajectory({color: 0x0000FF,
                                                      direction: 'primary'});
    gfx.trajectory2   =         new Omega.ShipTrajectory({color: 0x00FF00,
                                                      direction: 'secondary'});
    gfx.destruction   = new Omega.ShipDestructionEffect({config: config,
                                                       event_cb: event_cb});
    gfx.explosions    =   new Omega.ShipExplosionEffect({config: config,
                                                       event_cb: event_cb});
    gfx.smoke         =       new Omega.ShipSmokeEffect({config: config,
                                                       event_cb: event_cb});
    gfx.docking_audio     = new Omega.ShipDockingAudioEffect({config: config});
    gfx.mining_audio      = new Omega.ShipMiningAudioEffect({config: config});
    gfx.destruction_audio = new Omega.ShipDestructionAudioEffect({config: config});
    gfx.mining_completed_audio = new Omega.ShipMiningCompletedAudioEffect({config: config});
    gfx.combat_audio = new Omega.ShipCombatAudioEffect({config: config});
    gfx.movement_audio = new Omega.ShipMovementAudioEffect({config: config});
    Omega.Ship.gfx[this.type] = gfx;

    Omega.ShipMesh.load_template(config, this.type, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });

    this._loaded_gfx(this.type);
  },

  /// Intiialize ship graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(config, event_cb);
    this.components = [];

    this.components.push(this.position_tracker());
    this.position_tracker().add(this.location_tracker());

    /// TODO change highlight mesh material if ship doesn't belong to user
    this.highlight = Omega.Ship.gfx[this.type].highlight.clone();
    this.highlight.omega_entity = this;
    if(this.include_highlight)
      this.position_tracker().add(this.highlight.mesh);

    this.lamps = Omega.Ship.gfx[this.type].lamps.clone();
    this.lamps.omega_entity = this;
    this.lamps.init_gfx();

    this.trails = Omega.Ship.gfx[this.type].trails.clone(config, this.type, event_cb);
    this.trails.omega_entity = this;
    if(this.trails.particles) this.components.push(this.trails.particles.mesh);

    this.attack_vector =
      Omega.Ship.gfx[this.type].attack_vector.clone(config, event_cb);
    this.attack_vector.omega_entity = this;
    this.attack_vector.set_position(this.position_tracker().position);
    this.components.push(this.attack_vector.particles.mesh);

    this.mining_vector =
      Omega.Ship.gfx[this.type].mining_vector.clone(config, event_cb);
    this.mining_vector.omega_entity = this;
    this.components.push(this.mining_vector.particles.mesh);

    this.trajectory1   = Omega.Ship.gfx[this.type].trajectory1.clone();
    this.trajectory1.omega_entity = this;
    this.trajectory1.update();

    this.trajectory2   = Omega.Ship.gfx[this.type].trajectory2.clone();
    this.trajectory2.omega_entity = this;
    this.trajectory2.update();

    this.hp_bar = Omega.Ship.gfx[this.type].hp_bar.clone();
    this.hp_bar.omega_entity = this;
    this.hp_bar.bar.init_gfx(config, event_cb);
    if(this.include_hp_bar)
      for(var c = 0; c < this.hp_bar.bar.components.length; c++)
        this.position_tracker().add(this.hp_bar.bar.components[c]);

    this.destruction = Omega.Ship.gfx[this.type].destruction.clone(config, event_cb);
    this.destruction.omega_entity = this;
    this.destruction.set_position(this.position_tracker().position);
    this.components.push(this.destruction.particles.mesh);

    this.destruction_audio = Omega.Ship.gfx[this.type].destruction_audio;
    this.combat_audio = Omega.Ship.gfx[this.type].combat_audio;
    this.movement_audio = Omega.Ship.gfx[this.type].movement_audio;

    this.explosions = Omega.Ship.gfx[this.type].explosions.for_ship(this);
    this.explosions.omega_entity = this;
    this.components.push(this.explosions.particles.mesh);

    this.smoke = Omega.Ship.gfx[this.type].smoke.clone();
    this.smoke.omega_entity = this;
    this.components.push(this.smoke.particles.mesh);

    this.mining_audio = Omega.Ship.gfx[this.type].mining_audio;
    this.docking_audio = Omega.Ship.gfx[this.type].docking_audio;
    this.mining_completed_audio = Omega.Ship.gfx[this.type].mining_completed_audio;

    this.mesh = {update : function(){},
                 run_effects : function(){},
                 base_rotation : [0,0,0]};

    var _this = this;
    Omega.ShipMesh.load(this.type, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;

      for(var l = 0; l < _this.lamps.olamps.length; l++)
        _this.mesh.tmesh.add(_this.lamps.olamps[l].component);

      if(_this.debug_gfx){
        _this.mesh.tmesh.add(_this.trajectory1.mesh);
        _this.mesh.tmesh.add(_this.trajectory2.mesh);
      }

      _this.location_tracker().add(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
      _this._gfx_initializing = false;
      _this._gfx_initialized  = true;
    });

    this.last_moved = new Date();
    this.update_gfx();
    this.update_movement_effects();
  },

  /// Update ship graphics on movement events
  update_gfx : function(){
    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);
    this.location_tracker().rotation.setFromRotationMatrix(this.location.rotation_matrix());

    this.trails.update();
    this.attack_vector.update();
    this.mining_vector.update();
    this.smoke.update();
  },

  /// Update graphics on attack events
  update_attack_gfx : function(){
    this.attack_vector.update_state();
    this.attack_vector.update();
    this.explosions.update_state();
  },

  /// Update graphics on defense events
  update_defense_gfx : function(){
    this.hp_bar.update();
    this.smoke.update();
    this.smoke.update_state();
  },

  /// Update graphics on mining events
  update_mining_gfx : function(){
    this.mining_vector.update();
    this.mining_vector.update_state();
  },

  /// Update Movement Effects
  update_movement_effects : function(){
    if(this.location.is_moving('linear'))
      this._run_movement = this._run_linear_movement;
    else if(this.location.is_moving('follow'))
      this._run_movement = this._run_follow_movement;
    else if(this.location.is_moving('rotate'))
      this._run_movement = this._run_rotation_movement
    else if(this.location.is_stopped())
      this._run_movement = this._no_movement;

    if(this.trails) this.trails.update_state();
  },

  ///////////////////////////////////////////////// effects

  _run_linear_movement : function(){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var dist = this.location.movement_strategy.speed * elapsed / 1000;
    this.location.x += this.location.movement_strategy.dx * dist;
    this.location.y += this.location.movement_strategy.dy * dist;
    this.location.z += this.location.movement_strategy.dz * dist;

    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  },

  _run_rotation_movement : function(page, elapsed){
    var now     = new Date();
        elapsed = elapsed || (now - this.last_moved);
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
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  },

  _run_follow_movement : function(page){
    var now     = new Date();
    var elapsed = now - this.last_moved;

    var loc = this.location;
    var tracked = page.entity(loc.movement_strategy.tracked_location_id);
    loc.tracking = tracked.location; /// TODO need to clear tracking somewhere

    /// XXX rotation / linear movement here more or less corresponds
    ///     to logic in MovementStrategies::Follow#move
    var orientation_difference =
      this.location.orientation_difference(loc.tracking.x,
                                           loc.tracking.y,
                                           loc.tracking.z)
    var facing_target = Math.abs(orientation_difference[0]) <= (Math.PI / 32);
    if(this.location.movement_strategy.point_to_target && !facing_target)
      this._run_rotation_movement(page, elapsed);

    facing_target = Math.abs(orientation_difference[0]) <= (Math.PI / 8);
    if (!loc.on_target() && facing_target){
      var dx = loc.tracking.x - this.location.x;
      var dy = loc.tracking.y - this.location.y;
      var dz = loc.tracking.z - this.location.z;
      var distance = this.location.distance_from(loc.tracking);

      dx = dx / distance;
      dy = dy / distance;
      dz = dz / distance;

      var move_distance = loc.movement_strategy.speed * elapsed / 1000;

      loc.x += move_distance * dx;
      loc.y += move_distance * dy;
      loc.z += move_distance * dz;
    }else{
      this.update_movement_effects();
    }

    /// TODO move into if block above
    this.update_gfx();
    this.last_moved = now;
    this.dispatchEvent({type : 'movement', data : this});
  },

  _no_movement : function(){},

  /// Run ship graphics effects
  run_effects : function(page){
    this._run_movement(page);
    this.lamps.run_effects();
    this.trails.run_effects();

    this.attack_vector.run_effects();
    this.mining_vector.run_effects();
    this.explosions.run_effects();
    this.destruction.run_effects();
    this.smoke.run_effects();
  },

  /// Trigger ship destruction sequence
  trigger_destruction : function(cb){
    if(this.destruction) this.destruction.trigger(2000, cb);
  }
};

Omega.ShipGfx._run_movement = Omega.ShipGfx._no_movement;
$.extend(Omega.ShipGfx, Omega.EntityGfx);
