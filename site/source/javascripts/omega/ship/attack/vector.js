/* Omega Ship Attack Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/has_target"

Omega.ShipAttackVector = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var event_cb = args['event_cb'];
  var line     = args['line'];

  if(config)
    this.init_gfx(config, event_cb);
  if(line)
    this.line = line;

  this.disable_target_update();
};

Omega.ShipAttackVector.prototype = {
  init_gfx : function(config, event_cb){
    var mat = new THREE.LineBasicMaterial({color : 0xFF0000});
    var geo = new THREE.Geometry();
    geo.vertices.push(new THREE.Vector3(0, 0, 0));
    geo.vertices.push(new THREE.Vector3(0, 0, 0));
    this.line = new THREE.Line(geo, mat);
  },

  set_position : function(position){
    this.line.position = position;
  },

  clone : function(){
    return new Omega.ShipAttackVector({line : this.line.clone()});
  },

  target : function(){
    return this.omega_entity.attacking;
  },

  update_target_loc : function(){
    var new_loc = this.target().scene_location();
    this.target_loc(new_loc);
    this.line.geometry.vertices[1].set(new_loc.x, new_loc.y, new_loc.z);
  },

  enable : function(){
    this.omega_entity.components.push(this.line);
  },

  disable : function(){
    var index = this.omega_entity.components.indexOf(this.line);
    if(index != -1) this.oemga_entity.components.splice(index, 1);
  },
};

$.extend(Omega.ShipAttackVector.prototype, Omega.UI.HasTarget.prototype);
