/* Omega User JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.User = function(parameters){
  $.extend(this, parameters);
};

Omega.User.prototype = {
  json_class : 'Users::User'
};
