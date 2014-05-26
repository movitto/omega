/* Omega Star Geometry
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StarGeometry = {
  radius : 750,

  load : function(){
    /// each star instance should override radius in the geometry instance
    var segments = 32, rings = 32;
    return new THREE.SphereGeometry(this.radius, segments, rings);
  }
};
