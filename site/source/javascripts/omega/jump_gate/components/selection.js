/* Omega Jump Gate Selection Gfx & Helpers
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateSelectionMaterial = function(){
  this.material = new THREE.MeshBasicMaterial({color       : 0xffffff,
                                               transparent :     true,
                                               depthWrite  :    false,
                                               opacity     :      0.1,
                                               side        : THREE.DoubleSide});
};

Omega.JumpGateSelection = function(args){
  if(!args) args = {};
  var size     = args['size'];
  var material = args['material'];

  this.tmesh = this.init_gfx(size, material);
};

Omega.JumpGateSelection.prototype = {
  init_gfx : function(size, material){
    var segments = 32, rings = 32;
    var geometry = new THREE.SphereGeometry(size, segments, rings);
    return new THREE.Mesh(geometry, material);
  }
};

Omega.JumpGateSelection.for_jg = function(gate, material){
  var size = gate.trigger_distance/2;
  return new Omega.JumpGateSelection({size: size, material: material});
};
