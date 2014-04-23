/* Omega Jump Gate Selection Gfx & Helpers
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateSelectionMaterial = function(){
  this.material =
    new THREE.MeshBasicMaterial({color       : 0xffffff,
                                 transparent :     true,
                                 depthWrite  :    false,
                                 opacity     :      0.1});
};

Omega.JumpGateSelection = function(args){
  if(!args) args = {};
  var size = args['size'];

  this.tmesh = this.init_gfx(size);
};

Omega.JumpGateSelection.prototype = {
  init_gfx : function(size){
    var segments = 32, rings = 32,
        material = Omega.JumpGate.gfx.selection_material.material;
    var geometry = new THREE.SphereGeometry(size, segments, rings);
    return new THREE.Mesh(geometry, material);
  }
};

Omega.JumpGateSelection.for_jg = function(gate){
  var size = gate.trigger_distance/2/Omega.Config.scale_system;
  return new Omega.JumpGateSelection({size: size});
};
