/* Omega Star Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/entity/gfx"
//= require "omega/star/mesh"
//= require "omega/star/glow"
//= require "omega/star/light"

// Star Gfx Mixin

Omega.StarGfx = {
  async_gfx : 1,

  load_gfx : function(config, event_cb){
    if(this.gfx_loaded()) return;
    var gfx = {};

    gfx.meshes = Omega.StarMesh.for_types({config   : config,
                                           event_cb : event_cb});
    gfx.glow   = new Omega.StarGlow();
    gfx.light  = new Omega.StarLight();

    Omega.Star.gfx = gfx;
    this._loaded_gfx();
  },

  init_gfx : function(config, event_cb){
    if(this.gfx_initialized()) return;
    this.load_gfx(config, event_cb);

    this.mesh = Omega.StarMesh.for_type(this.type,
                                        Omega.Star.gfx.meshes).clone();
    this.mesh.omega_entity = this;

    this.glow = Omega.Star.gfx.glow.clone();
    this.glow.tglow.position = this.mesh.tmesh.position;

    this.light = Omega.Star.gfx.light.clone();
    this.light.position = this.mesh.tmesh.position;
    this.light.color.setHex(this.type_int);

    this.components = [this.glow.tglow, this.mesh.tmesh, this.light];
    this._gfx_initialized = true;
  },

  /// Not current needed for star, for api compatability
  update_gfx : function(){},
  run_effects : function(){}
};

$.extend(Omega.StarGfx, Omega.EntityGfx);
