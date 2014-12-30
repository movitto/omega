/* Omega Location Coordinates Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationCoordinates = {
  /// Set coordinates,
  /// - accepts each coordinate as an individual param: loc.set(1,2,3)
  /// - or a single param w/ array of coordinates: loc.set([1,2,3])
  set : function(x,y,z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location'){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    this.x = x;
    this.y = y;
    this.z = z;
    return this;
  },

  /// Return coordinates as an array
  coordinates : function(){
    return [this.x, this.y, this.z];
  },

  /// Add specified values to location's coordinates
  add : function(x, y, z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location' || x.constructor == THREE.Vector3){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    this.x += x;
    this.y += y;
    this.z += z;
    return this;
  },

  /// Return array containing the difference between location's coordinates
  /// and the specified coordiantes
  sub : function(x, y, z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }

    return [this.x - x, this.y - y, this.z - z];
  },

  // Return array containing this location's coordinates divided by
  // specified scalar
  divide : function(scalar){
    return [this.x / scalar, this.y / scalar, this.z / scalar];
  },

  /// Returns the unit direction vector from this location's
  /// coords to the specified coords
  direction_to : function(x, y, z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location' || x.constructor == THREE.Vector3){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    var d    = this.distance_from(x, y, z);
    var dx   = x - this.x;
    var dy   = y - this.y;
    var dz   = z - this.z;

    return [dx / d, dy / d, dz / d];
  },

  /* Return distance location is from the specified x,y,z
   * coordinates
   */
  distance_from : function(x,y,z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }else if(x.json_class == 'Motel::Location' || x.constructor == THREE.Vector3){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    return Math.sqrt(Math.pow(this.x - x, 2) +
                     Math.pow(this.y - y, 2) +
                     Math.pow(this.z - z, 2));
  },

  // Return absolute length of location
  length : function(){
    return this.distance_from(0,0,0);
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
    return this.x.toExponential(2) + "/" +
           this.y.toExponential(2) + "/" +
           this.z.toExponential(2);
  }
};
