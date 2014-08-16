/* Omega JS SolarSystem Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemGfxInitializer = {
  _init_mesh : function(){
    this.mesh = this._retrieve_resource('mesh').clone();
    this.mesh.omega_entity = this;
  },

  _init_plane : function(){
    this.plane = this._retrieve_resource('plane').clone();
    this.plane.omega_entity = this;
  },

  _init_text : function(){
    var material = this._retrieve_resource('text_material').material;
    this.text = new Omega.SolarSystemText({text: this.title(), material: material})
    this.text.omega_entity = this;
  },

  _init_audio : function(){
    this.hover_audio = this._retrieve_resource('hover_audio');
    this.click_audio = this._retrieve_resource('click_audio');
  },

  _init_particles : function(){
    this.particles = this._retrieve_resource('particles').clone();
    this.particles.omega_entity = this;
  },

  _init_interconns : function(){
    this.interconns.init_gfx(event_cb);
  },

  _init_components : function(){
    this.position_tracker().add(this.plane.tmesh);
    this.position_tracker().add(this.text.text);
    this.position_tracker().add(this.particles.component());
    this.position_tracker().add(this.interconns.component());
    this.components = [this.position_tracker()];
  },

  // Initialize local system graphics
  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);

    this._init_mesh();
    this._init_plane();
    this._init_text();
    this._init_audio();
    this._init_particles();
    this._init_interconns(event_cb);
    this._init_components();

    this._gfx_initialized = true;
    this.interconns.unqueue();
    this.update_gfx();
  }
};
