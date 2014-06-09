/* Omega JS Sector
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// A sector is an arbitrary section of space
Omega.Sector = function(parameters){
  this.children   = [];
  $.extend(this, parameters);
};

Omega.Sector.prototype = {
  scene_children : function(){
    return this.children;
  }
};
