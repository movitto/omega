/* Omega Asteroid JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Asteroid = function(parameters){
  $.extend(this, parameters);
};

Omega.Asteroid.prototype = {
  json_class : 'Cosmos::Entities::Asteroid'
};
