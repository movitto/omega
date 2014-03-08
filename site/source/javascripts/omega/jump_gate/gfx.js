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
  async_gfx : 3,

  // True/False if shared gfx are loaded
  gfx_loaded : function(){
    return typeof(Omega.JumpGate.gfx) !== 'undefined';
  },

  /// Load shared graphics resources
  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;

    var gfx            = {};
    Omega.JumpGate.gfx = gfx;
    gfx.mesh_material  = new Omega.JumpGateMeshMaterial({config: config,
                                                         event_cb: event_cb});
    gfx.lamp           = new Omega.JumpGateLamp();
    gfx.particles      = new Omega.JumpGateParticles({config: config,
                                                      event_cb: event_cb});
    gfx.selection_material = new Omega.JumpGateSelectionMaterial();

    Omega.JumpGateMesh.load_template(config, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });
  },

  // True / false if local system gfx have been initialized
  gfx_initialized : function(){
    return this.components.length > 0;
  },

  // Intiialize local jump gate graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
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

    this.particles = Omega.JumpGate.gfx.particles.clone({config: config,
                                                         event_cb: event_cb});
    this.particles.omega_entity = this;
    this.components.push(this.particles.particles.mesh);

    this.selection = Omega.JumpGateSelection.for_jg(this);
    this.selection.omega_entity = this;

    this.update_gfx();
  },

  // Run local jump gate graphics effects
  run_effects : function(){
    this.lamp.run_effects();
    this.particles.run_effects();
    if(this.mesh) this.mesh.run_effects();
  },

  // Update local jump gate graphics on core entity changes
  update_gfx : function(){
    if(!this.location) return;

    if(this.mesh)      this.mesh.update();
    if(this.lamp)      this.lamp.update();
    if(this.particles) this.particles.update();
    if(this.selection) this.selection.update();
  }
}
