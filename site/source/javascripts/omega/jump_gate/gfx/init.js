/* Omega JS JumpGate Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateGfxInitializer = {
  _init_components : function(){
    this.components = [this.position_tracker(), this.camera_tracker()];
  },

  _init_lamps : function(){
    this.lamp = this._retrieve_resource('lamp').clone();
    this.lamp.omega_entity = this;
    this.lamp.olamp.init_gfx();
  },

  _init_particles : function(){
    this.particles = this._retrieve_resource('particles').clone();
    this.particles.omega_entity = this;
    this.position_tracker().add(this.particles.component());
  },

  _init_selection : function(){
    var material = this._retrieve_resource('selection_material').material;
    this.selection = Omega.JumpGateSelection.for_jg(this, material);
    this.selection.omega_entity = this;
  },

  _init_audio : function(){
    this.trigger_audio = this._retrieve_resource('trigger_audio');
  },

  _init_mesh : function(){
    var _this = this;
    this._retrieve_async_resource('jump_gate.geometry', function(geometry){
      var material = _this._retrieve_resource('mesh_material').material;
      var mesh     = new Omega.JumpGateMesh({geometry : geometry,
                                             material : material});
      _this.mesh = mesh;
      _this.mesh.omega_entity = _this;
      _this.mesh.tmesh.add(_this.lamp.olamp.component);
      _this.position_tracker().add(_this.mesh.tmesh);

      _this.update_gfx();
      _this._gfx_initialized = true;
    });
  },

  // Intiialize local jump gate graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);
    this._init_components();
    this._init_lamps();
    this._init_particles();
    this._init_selection();
    this._init_audio();
    this._init_mesh();
    this.update_gfx();
  }
};
