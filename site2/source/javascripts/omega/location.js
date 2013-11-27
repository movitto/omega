/* Omega Location JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Location = function(parameters){
  $.extend(this, parameters);
};

Omega.Location.prototype = {
  json_class : 'Motel::Location',

  /* Return distance location is from the specified x,y,z
   * coordinates
   */
  distance_from : function(loc){
    return Math.sqrt(Math.pow(this.x - loc.x, 2) +
                     Math.pow(this.y - loc.y, 2) +
                     Math.pow(this.z - loc.z, 2));
  },

  /* Return boolean indicating if location is less than the
   * specified distance from the specified location
   */
  is_within : function(distance, loc){
    if(this.parent_id != loc.parent_id)
      return false
    return  this.distance_from(loc) < distance;
  },

  /* Convert location to short, human readable string
   */
  to_s : function(){
    return Omega.Math.round_to(this.x, 2) + "/" +
           Omega.Math.round_to(this.y, 2) + "/" +
           Omega.Math.round_to(this.z, 2);
  }
};
