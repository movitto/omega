/* Omega Ship JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Ship = function(parameters){
  $.extend(this, parameters);
};

Omega.Planet.prototype = {
  json_class : 'Manufactured::Ship'
};
