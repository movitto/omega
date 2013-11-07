/* Omega Station JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Station = function(parameters){
  $.extend(this, parameters);
};

Omega.Station.prototype = {
  json_class : 'Manufactured::Station'
};
