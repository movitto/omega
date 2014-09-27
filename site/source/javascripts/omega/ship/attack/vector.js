/* Omega Ship Attack Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/canvas/components/has_target"

Omega.ShipAttackVector = function(){
  this.init_gfx();
};

Omega.ShipAttackVector.prototype = {
  init_gfx : function(){
    var mat = new THREE.LineBasicMaterial({color : 0xFF0000});
    var geo = new THREE.Geometry();
    geo.vertices.push(new THREE.Vector3(0, 0, 0));
    geo.vertices.push(new THREE.Vector3(0, 0, 0));
    this.line = new THREE.Line(geo, mat);
  },

  clone : function(){
    return new Omega.ShipAttackVector();
  },

  target : function(){
    return this.omega_entity.attacking;
  },

  update : function(){
    var new_loc = this.target().scene_location();
    this.target_loc(new_loc);

    var loc = this.omega_entity.scene_location()
    var dir  = loc.direction_to(new_loc.x, new_loc.y, new_loc.z);
    var dist = loc.distance_from(new_loc.x, new_loc.y, new_loc.z);
    this.line.geometry.vertices[1].set(dir[0] * dist, dir[1] * dist, dir[2] * dist);
    this.line.geometry.verticesNeedUpdate = true;
  },

  enabled : function(){
    var descendants = this.omega_entity.position_tracker().getDescendants();
    return descendants.indexOf(this.line) != -1;
  },

  enable : function(){
    if(!this.enabled()) this.omega_entity.position_tracker().add(this.line);
  },

  disable : function(){
    if(this.enabled()) this.omega_entity.position_tracker().remove(this.line);
  }
};

$.extend(Omega.ShipAttackVector.prototype, Omega.UI.HasTarget);
