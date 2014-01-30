/* Omega Location JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.Location = function(parameters){
  $.extend(this, parameters);
  this.update_ms();
};

Omega.Location.prototype = {
  constructor: Omega.Location,
  json_class : 'Motel::Location',

  toJSON : function(){
    return {json_class : this.json_class,
            id : this.id,
            x : this.x,
            y : this.y,
            z : this.z,
            orientation_x : this.orientation_x,
            orientation_y : this.orientation_y,
            orientation_z : this.orientation_z,
            parent_id : this.parent_id,
            movement_strategy : this.movement_strategy};
  },

  update_ms : function(ms){
    if(ms != null){
      this.movement_strategy = ms;
    }

    // XXX currently no js obj for movement strategy
    if(this.movement_strategy && this.movement_strategy.data){
      $.extend(this.movement_strategy, this.movement_strategy.data);
      delete this.movement_strategy['data'];
    }
  },

  set : function(x,y,z){
    if(typeof(x) === "array" && x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }

    this.x = x;
    this.y = y;
    this.z = z;
    return this;
  },

  orientation : function(){
    return [this.orientation_x, this.orientation_y, this.orientation_z];
  },

  clone : function(){
     var cloned = new Omega.Location();
     return $.extend(true, cloned, this); /// deep copy
  },

  /* Return distance location is from the specified x,y,z
   * coordinates
   */
  distance_from : function(x,y,z){
    if(x.json_class == 'Motel::Location'){
      z = x.z;
      y = x.y;
      x = x.x;
    }

    return Math.sqrt(Math.pow(this.x - x, 2) +
                     Math.pow(this.y - y, 2) +
                     Math.pow(this.z - z, 2));
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
  },

  /* Convert orientation to short, human readable string
   */
  orientation_s : function(){
    return Omega.Math.round_to(this.orientation_x, 2) + "/" +
           Omega.Math.round_to(this.orientation_y, 2) + "/" +
           Omega.Math.round_to(this.orientation_z, 2);
  },

  /// return rotation matrix generated from axis angle
  /// between location's orientation and base cartesion
  /// orientation we're using
  rotation_matrix : function(){
    var axis = Omega.Math.cp(0, 0, 1,
                             this.orientation_x,
                             this.orientation_y,
                             this.orientation_z);
    var angle = Omega.Math.abwn(0, 0, 1,
                                this.orientation_x,
                                this.orientation_y,
                                this.orientation_z);
    if(!angle == 0) axis = Omega.Math.nrml(axis[0], axis[1], axis[2]);
    var matrix = new THREE.Matrix4().
                     makeRotationAxis({x: axis[0],
                                       y: axis[1],
                                       z: axis[2]}, angle);
    return matrix;
  }
};
