/* Omega JS Ship Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/entity/gfx_stub"

Omega.ShipGfxInitializer = {
  debug_gfx : false,
  include_highlight : true,
  include_hp_bar    : true,

  _init_stubs : function(){
    /// stub out asynchronously loaded components until they are available
    this.mesh = Omega.UI.CanvasEntityGfxStub.instance();
    this.missiles = Omega.UI.CanvasEntityGfxStub.instance();
  },

  _init_components : function(){
    this.components = [];
    this.components.push(this.position_tracker());
    this.position_tracker().add(this.location_tracker());
  },

  _init_highlight : function(){
    /// TODO change highlight mesh material if ship doesn't belong to user
    this.highlight = this._retrieve_resource('highlight').clone();
    this.highlight.omega_entity = this;
    if(this.include_highlight)
      this.position_tracker().add(this.highlight.mesh);
  },

  _init_lamps : function(){
    this.lamps = this._retrieve_resource('lamps').clone();
    this.lamps.omega_entity = this;
    this.lamps.init_gfx();
  },

  _init_trails : function(){
    this.trails = this._retrieve_resource('trails').clone();
    this.trails.omega_entity = this;
    if(this.trails.particles) this.components.push(this.trails.particles.mesh);
  },

  _init_visited_route : function(){
    this.visited_route = this._retrieve_resource('visited_route').clone();
    this.visited_route.omega_entity = this;
    this.components.push(this.visited_route.line);
  },

  _init_attack_vector : function(){
    this.attack_vector = this._retrieve_resource('attack_vector').clone();
    this.attack_vector.omega_entity = this;
    this.attack_vector.set_position(this.position_tracker().position);
  },

  _init_artillery : function(){
    this.artillery = this._retrieve_resource('artillery').clone();
    this.artillery.omega_entity = this;
  },

  _init_mining_vector : function(){
    this.mining_vector = this._retrieve_resource('mining_vector').clone();
    this.mining_vector.omega_entity = this;
    this.components.push(this.mining_vector.particles.mesh);
  },

  _init_trajectory : function(){
    this.trajectory1 = this._retrieve_resource('trajectory1').clone();
    this.trajectory1.omega_entity = this;
    this.trajectory1.update();

    this.trajectory2 = this._retrieve_resource('trajectory2').clone();
    this.trajectory2.omega_entity = this;
    this.trajectory2.update();
  },

  _init_hp_bar : function(){
    this.hp_bar = this._retrieve_resource('hp_bar').clone();
    this.hp_bar.omega_entity = this;
    this.hp_bar.bar.init_gfx();
    if(this.include_hp_bar)
      for(var c = 0; c < this.hp_bar.bar.components.length; c++)
        this.position_tracker().add(this.hp_bar.bar.components[c]);
  },

  _init_destruction : function(){
    this.destruction = this._retrieve_resource('destruction').clone();
    this.destruction.omega_entity = this;
    this.destruction.set_position(this.position_tracker().position);
    this.components.push(this.destruction.particles.mesh);
  },

  _init_audio : function(){
    this.destruction_audio      = this._retreive_resource('destruction_audio');
    this.combat_audio           = this._retrieve_resource('combat_audio');
    this.movement_audio         = this._retrieve_resource('movement_audio');
    this.mining_audio           = this._retrieve_resource('mining_audio');
    this.docking_audio          = this._retrieve_resource('docking_audio');
    this.mining_completed_audio = this._retrieve_resource('mining_completed_audio');
  },

  _init_explosions : function(){
    this.explosions = this._retrieve_resource('explosions').for_ship(this);
    this.explosions.omega_entity = this;
    this.components.push(this.explosions.particles.mesh);
  },

  _init_smoke : function(){
    this.smoke = this._retrieve_resource('smoke').clone();
    this.smoke.omega_entity = this;
    this.components.push(this.smoke.particles.mesh);
  },

  _add_lamp_components : function(){
    for(var l = 0; l < this.lamps.olamps.length; l++)
      this.mesh.tmesh.add(this.lamps.olamps[l].component);
  },

  _add_trajectory_components : function(){
    if(this.debug_gfx){
      this.mesh.tmesh.add(this.trajectory1.mesh);
      this.mesh.tmesh.add(this.trajectory2.mesh);
    }
  },

  _init_mesh : function(){
    var _this = this;

    var mesh_geometry = 'ship.' + this.type + '.mesh_geometry';
    Omega.UI.AsyncResourceLoader.retrieve(mesh_geometry, function(geometry){
      var material = _this._retrieve_resource('mesh_material').material;
      var mesh = new Omega.ShipMesh({material: material.clone(),
                                     geometry: geometry.clone()});
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this._add_lamp_components();
      _this._add_trajectory_components();
      _this.location_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this.mesh_init = true;
      _this._finish_init();
    });
  },

  _init_missiles : function(){
    var _this     = this;

    var missile_geometry = 'ship.' + this.type + '.missile_geometry';
    Omega.UI.AsyncResourceLoader.retrieve(missile_geometry, function(geometry){
      var material = new THREE.MeshBasicMaterial({color : 0x000000});
      var template = new Omega.ShipMissile({geometry: geometry.clone(),
                                            material: material});
      var missiles = new Omega.ShipMissiles({template: template});

      _this.missiles = missiles;
      _this.missiles.omega_entity = _this;

      _this.missiles_init = true;
      _this._finish_init();
    });
  },

  _finish_init : function(){
    if(this.mesh_init && this.missiles_init){
      this._gfx_initializing = false;
      this._gfx_initialized  = true;
    }
  },

  /// Intiialize ship graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this._gfx_initializing = true;
    this.load_gfx(event_cb);

    this._init_stubs();
    this._init_components();
    this._init_highlight();
    this._init_lamps();
    this._init_trails();
    this._init_visited_route();
    this._init_attack_vector();
    this._init_artillery();
    this._init_mining_vector();
    this._init_trajectory();
    this._init_hp_bar();
    this._init_destruction();
    this._init_explosions();
    this._init_smoke();

    this._init_mesh();
    this._init_missiles();

    this.last_moved = new Date();
    this.update_gfx();
    this.update_movement_effects();
  },

  /// Return the attack component corresponding to the specified weapons class
  attack_component : function(){
    switch(this.weapons_class_type()){
      case "light": return this.artillery;
      case "heavy": return this.missiles;
    }
    return Omega.UI.CanvasEntityGfxStub.instance();
  }
};
