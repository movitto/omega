/* Omega Jump Gate Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require 'omega/jump_gate/mesh'
//= require 'omega/jump_gate/lamp'
//= require 'omega/jump_gate/particles'
//= require 'omega/jump_gate/selection'

// JumpGate GFX Mixin
Omega.JumpGateGfx = {
  gfx_props : {
    particle_plane :  20,
    particle_life  : 200,
    lamp_x         : -02,
    lamp_y         : -17,
    lamp_z         : 175,
    particles_x    : -10,
    particles_y    : -25,
    particles_z    :  75
  },

  async_gfx : 3,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.JumpGate.gfx) !== 'undefined') return;
    var gfx = {};
    Omega.JumpGate.gfx = gfx;

    gfx.mesh_material      = new Omega.JumpGateMeshMaterial(config, event_cb);
    gfx.lamp               = new Omega.JumpGateLamp();
    gfx.particles          = new Omega.JumpGateParticles(config, event_cb);
    gfx.selection_material = new Omega.JumpGateSelectionMaterial();

    Omega.JumpGateMesh.load_template(config, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    this.components = [];

    var _this = this;
    Omega.JumpGateMesh.load(config, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.components.push(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
    });

    this.lamp = Omega.JumpGate.gfx.lamp.clone();
    this.lamp.omega_entity = this;
    this.lamp.olamp.init_gfx();
    this.components.push(this.lamp.olamp.component);

    this.particles = Omega.JumpGate.gfx.particles.clone();
    this.particles.omega_entity = this;
    this.components.push(this.particles.particle_system);

    this.selection = Omega.JumpGateSelection.for_jg(this);
    this.selection.omega_entity = this;

    this.update_gfx();
  },

  run_effects : function(){
    this.lamp.run_effects();
    this.particles.run_effects();
  },

  update_gfx : function(){
    if(!this.location) return;

    if(this.mesh)      this.mesh.update();
    if(this.lamp)      this.lamp.update();
    if(this.particles) this.particles.update();
    if(this.selection) this.selection.update();
  }
}
