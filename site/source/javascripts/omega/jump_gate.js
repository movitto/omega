/* Omega JumpGate JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/jump_gate/commands"
//= require "omega/jump_gate/gfx"

Omega.JumpGate = function(parameters){
  this.components = [];
  this.shader_components = [];
  $.extend(this, parameters);

  this.location = Omega.convert_entity(this.location)
};

Omega.JumpGate.prototype = {
  constructor : Omega.JumpGate,
  json_class : 'Cosmos::Entities::JumpGate',

  toJSON : function(){
    return {json_class  : this.json_class,
            id          : this.id,
            name        : this.name,
            location    : this.location ? this.location.toJSON() : null,
            parent_id   : this.parent_id,
            endpoint_id : this.endpoint_id,
            trigger_distance : this.trigger_distance};
  },

  endpoint_title : function(){
    return this.endpoint ? this.endpoint.name : this.endpoint_id;
  },

  has_details : true,

  selected : function(page){
    var _this = this;
    page.canvas.reload(this, function(){
      if($.inArray(_this.selection_sphere, _this.components) == -1)
        _this.components.push(_this.selection_sphere);
    });
  },

  unselected : function(page){
    var _this = this;
    page.canvas.reload(this, function(){
      var index;
      if((index = $.inArray(_this.selection_sphere, _this.components)) != -1)
        _this.components.splice(index, 1);
    });
  },

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
    Omega.JumpGate.gfx = {};
    Omega.load_jump_gate_gfx(config, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_jump_gate_gfx(config, this, event_cb);
  }
};

Omega.UI.ResourceLoader.prototype.apply(Omega.JumpGate.prototype);
$.extend(Omega.JumpGate.prototype, Omega.JumpGateCommands);
$.extend(Omega.JumpGate.prototype, Omega.JumpGateEffectRunner);
