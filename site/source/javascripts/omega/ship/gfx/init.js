/* Omega JS Ship Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx_stub"

Omega.ShipGfxInitializer = {
  debug_gfx : false,
  include_highlight : true,
  include_hp_bar    : true,

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

    this.visited_route = Omega.Ship.gfx[this.type].visited_route.clone();
    this.visited_route.omega_entity = this;
    this.components.push(this.visited_route.line);

    /// TODO config option to set weapon(s) originating coordinates on mesh on per-ship-type basis
    this.attack_vector =
      Omega.Ship.gfx[this.type].attack_vector.clone(config, event_cb);
    this.attack_vector.omega_entity = this;
    this.attack_vector.set_position(this.position_tracker().position);

    this.artillery = Omega.Ship.gfx[this.type].artillery.clone(config, event_cb);
    this.artillery.omega_entity = this;
    this.artillery.set_position(this.position_tracker().position);

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

    if(this.attack_component() == this.artillery){
      this.components.push(this.attack_component().component());
      this.explosions.interval = this.artillery.interval();
      this.explosions.auto_trigger = true;
    }

    var _this     = this;
    this.mesh     = Omega.EntityGfxStub.instance();
    this.missiles = Omega.EntityGfxStub.instance();

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

    Omega.ShipMissiles.load(this.type, function(missiles){
      _this.missiles = missiles;
      _this.missiles.omega_entity = _this;
    });

    this.last_moved = new Date();
    this.update_gfx();
    this.update_movement_effects();
  },

  /// Return the attack corresponent corresponding to the specified weapons class
  attack_component : function(){
    switch(this.weapons_class_type()){
      case "light": return this.artillery;
      case "heavy": return this.missiles;
    }
    return Omega.EntityGfxStub.instance();
  }
};
