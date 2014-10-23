/* Omega JS Star Graphics Initializer
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarGfxInitializer = {
  _init_mesh : function(){
    this.mesh = this._retrieve_resource('mesh').clone(); 
    this.mesh.omega_entity = this;
  },

  _init_glow : function(){
    this.glow = this._retrieve_resource('glow').clone();
    this.glow.tglow.position = this.mesh.tmesh.position;
    this.glow.set_color(this.type_int);
  },

  _init_surface : function(){
    this.surface = this._retrieve_resource('surface').clone();
    this.surface.omega_entity = this;
  },

  _init_halo : function(){
    this.halo = this._retrieve_resource('halo').clone();
    this.halo.tmesh.position = this.halo.tmesh.position;
    this.halo.omega_entity = this;
  },

  _init_light : function(){
    this.light = this._retrieve_resource('light').clone();
    this.light.position = this.mesh.tmesh.position;
    this.light.color.setHex(this.type_int);
  },

  _init_components : function(){
    //this.components = [this.glow.tglow, this.mesh.tmesh, this.light];
    this.components = [this.surface.tmesh, this.halo.tmesh, this.light];
  },

  init_gfx : function(event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(event_cb);
    this._init_mesh();
    this._init_glow();
    this._init_surface();
    this._init_halo();
    this._init_light();
    this._init_components();
    this.started = Date.now();

    this._gfx_initialized = true;
  }
};
