/* Omega Resource JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Resource = function(parameters){
  $.extend(this, parameters);
};

Omega.Resource.prototype = {
  json_class : 'Cosmos::Resource'
};
