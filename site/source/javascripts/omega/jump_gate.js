/* Omega JumpGate JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/jump_gate/commands"
//= require "omega/jump_gate/gfx"

Omega.JumpGate = function(parameters){
  this.components = [];
  $.extend(this, parameters);

  this.location = Omega.convert.entity(this.location)
};

Omega.JumpGate.prototype = {
  constructor : Omega.JumpGate,
  json_class : 'Cosmos::Entities::JumpGate',

  /// Return jump gate in JSON format
  toJSON : function(){
    return {json_class  : this.json_class,
            id          : this.id,
            name        : this.name,
            location    : this.location ? this.location.toJSON() : null,
            parent_id   : this.parent_id,
            endpoint_id : this.endpoint_id,
            trigger_distance : this.trigger_distance};
  },

  /// The human friendly name of the endpoint,
  /// - the endpoint system name if the endpoint system is loaded
  /// - the endpoint_id otherwise
  endpoint_title : function(){
    return this.endpoint ? this.endpoint.name : this.endpoint_id;
  },

  /// TODO move these methods to omega/jump_gate/selection

  _has_selection_sphere : function(){
    return $.inArray(this.selection.tmesh, this.mesh.tmesh.getDescendants()) != -1;
  },

  _add_selection_sphere : function(){
    this.mesh.tmesh.add(this.selection.tmesh);
  },

  _rm_selection_sphere : function(){
    this.mesh.tmesh.remove(this.selection.tmesh);
  },

  clicked_in : function(canvas){
    canvas.follow_entity(this);
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

$.extend(Omega.JumpGate.prototype, Omega.JumpGateGfx);
$.extend(Omega.JumpGate.prototype, Omega.JumpGateCommands);
