/* Omega Galaxy JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Galaxy = function(parameters){
  $.extend(this, parameters);

  this.bg = 'galaxy' + this.background;
};

Omega.Galaxy.prototype = {
  json_class : 'Cosmos::Entities::Galaxy'
};
