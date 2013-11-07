/* Omega SolarSystem JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystem = function(parameters){
  $.extend(this, parameters);

  this.bg = 'system' + this.background;
};

Omega.SolarSystem.prototype = {
  json_class : 'Cosmos::Entities::SolarSystem'
};
