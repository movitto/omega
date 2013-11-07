/* Omega Mission JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Mission = function(parameters){
  $.extend(this, parameters);
};

Omega.Mission.prototype = {
  json_class : 'Missions::Mission'
};
