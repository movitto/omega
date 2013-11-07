/* Omega Planet JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Planet = function(parameters){
  $.extend(this, parameters);
};

Omega.Planet.prototype = {
  json_class : 'Cosmos::Entities::Planet'
};
