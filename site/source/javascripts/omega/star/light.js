/* Omega Star Light
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarLight = function(){
  // each star instance should set the color/position of their light instance
  var color = '0xFFFFFF';
  var light = new THREE.PointLight(color, 1);
  $.extend(this, light);
};
