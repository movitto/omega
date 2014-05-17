/* Omega Jump Gate Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx"
//= require 'omega/jump_gate/mesh'
//= require 'omega/jump_gate/lamp'
//= require 'omega/jump_gate/particles'
//= require 'omega/jump_gate/selection'
//= require 'omega/jump_gate/trigger_audio'

// JumpGate GFX Mixin
Omega.JumpGateGfx = {
  async_gfx : 3,

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
    gfx.trigger_audio = new Omega.JumpGateTriggerAudioEffect({config: config});

    Omega.JumpGateMesh.load_template(config, function(mesh){
      gfx.mesh = mesh;
      if(event_cb) event_cb();
    });

    this._loaded_gfx();
  },

  // Intiialize local jump gate graphics
  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);
    this.components = [];

    this.lamp = Omega.JumpGate.gfx.lamp.clone();
    this.lamp.omega_entity = this;
    this.lamp.olamp.init_gfx();

    this.particles = Omega.JumpGate.gfx.particles.clone(config, event_cb);
    this.particles.omega_entity = this;
    this.components.push(this.particles.particles.mesh);

    this.selection = Omega.JumpGateSelection.for_jg(this);
    this.selection.omega_entity = this;

    this.trigger_audio = Omega.JumpGate.gfx.trigger_audio;

    var _this = this;
    Omega.JumpGateMesh.load(config, function(mesh){
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.mesh.tmesh.add(_this.lamp.olamp.component);
      _this.position_tracker().add(_this.mesh.tmesh);
      _this.update_gfx();
      _this.loaded_resource('mesh', _this.mesh);
      _this._gfx_initialized = true;
    });

    this.components.push(this.position_tracker());
    this.update_gfx();
  },

  // Run local jump gate graphics effects
  run_effects : function(){
    this.lamp.run_effects();
    this.particles.run_effects();
    this.mesh.run_effects();
  },

  update_gfx : function(){
    if(!this.scene_location()) return;

    var loc = this.scene_location();
    this.position_tracker().position.set(loc.x, loc.y, loc.z);

    if(this.particles) this.particles.update();
  }
}

$.extend(Omega.JumpGateGfx, Omega.EntityGfx);
