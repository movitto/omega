/* Omega Javascript Location
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Location
 */
function Location(args){
  $.extend(this, new Entity(args));
  this.json_class = 'Motel::Location';

  // ignore movement strategy so as to not have to
  // convert into object to be able to send it to the server
  // (otherwise we'll get parsing errs)
  this.ignore_properties.push('movement_strategy');

  /* Return distance location is from the specified x,y,z
   * coordinates
   */
  this.distance_from = function(x, y, z){
    return Math.sqrt(Math.pow(this.x - x, 2) +
                     Math.pow(this.y - y, 2) +
                     Math.pow(this.z - z, 2));
  };

  /* Return boolean indicating if location is less than the
   * specified distance from the specified location
   */
  this.is_within = function(distance, loc){
    if(this.parent_id != loc.parent_id)
      return false
    return  this.distance_from(loc.x, loc.y, loc.z) < distance;
  };

  /* Convert location to short, human readable string
   */
  this.to_s = function(){
    return roundTo(this.x, 2) + "/" +
           roundTo(this.y, 2) + "/" +
           roundTo(this.z, 2);
  }
}

