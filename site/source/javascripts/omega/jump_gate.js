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

  /// TODO move these methods to omega/jump_gate/selection

  _has_selection_sphere : function(){
    return $.inArray(this.selection.tmesh, this.components) != -1;
  },

  _add_selection_sphere : function(){
    this.components.push(this.selection.tmesh);
  },

  _rm_selection_sphere : function(){
    var index = $.inArray(this.selection.tmesh, this.components);
    this.components.splice(index, 1);
  },

  selected : function(page){
    var _this = this;
    page.canvas.reload(this, function(){
      if(!_this._has_selection_sphere()) _this._add_selection_sphere();
    });
  },

  unselected : function(page){
    var _this = this;
    page.canvas.reload(this, function(){
      if(_this._has_selection_sphere()) _this._rm_selection_sphere();
    });
  },
};

Omega.UI.ResourceLoader.prototype.apply(Omega.JumpGate.prototype);
$.extend(Omega.JumpGate.prototype, Omega.JumpGateGfx);
$.extend(Omega.JumpGate.prototype, Omega.JumpGateCommands);
