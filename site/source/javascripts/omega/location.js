/* Omega Location JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.Location = function(parameters){
  $.extend(this, parameters);
  this.update_ms();
};

Omega.Location.prototype = {
  constructor: Omega.Location,
  json_class : 'Motel::Location',

  /// Return location in JSON format
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

  /// Return THREE.Vector3 instance w/ location's coordinates
  vector : function(){
    return new THREE.Vector3(this.x, this.y, this.z);
  },

  /// Update this locations attributes from another
  update : function(loc){
    this.x = loc.x;
    this.y = loc.y;
    this.z = loc.z;
    this.orientation_x = loc.orientation_x;
    this.orientation_y = loc.orientation_y;
    this.orientation_z = loc.orientation_z;
    this.parent_id = loc.parent_id;
    this.last_moved_at = loc.last_moved_at;
    this.angle_rotated = loc.angle_rotated;
    this.distance_moved = loc.distance_moved;
    this.update_ms(loc.movement_strategy);
  },

  /// Special case to update movement strategy since ms doesn't
  /// currently have it's own JS class heirarchy
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

  /// Alias for movement_strategy
  ms : function(){ return this.movement_strategy; },

  /// Set coordinates,
  /// - accepts each coordinate as an individual param: loc.set(1,2,3)
  /// - or a single param w/ array of coordinates: loc.set([1,2,3])
  set : function(x,y,z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
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

  /// Return location orientation in an array
  orientation : function(){
    return [this.orientation_x, this.orientation_y, this.orientation_z];
  },

  /// Return location orientation in a THREE.Vector3
  orientation_vector : function(){
    return new THREE.Vector3(this.orientation_x,
                             this.orientation_y,
                             this.orientation_z);
  },

  /// Set orientation,
  /// - accepts each component as an indivisual param: loc.set_orientation(0,0,1);
  /// - or a single param w/ an array: loc.set_orientation([0,0,1]);
  set_orientation : function(x,y,z){
    if((typeof(x) === "array" || typeof(x) === "object") &&
       x.length == 3 && !y && !z){
      y = x[1];
      z = x[2];
      x = x[0];
    }

    this.orientation_x = x;
    this.orientation_y = y;
    this.orientation_z = z;
    return this;
  },

  /// Return axis angle between location's orientation and specified coordinate
  orientation_difference : function(x, y, z){
    var dx = x - this.x;
    var dy = y - this.y;
    var dz = z - this.z;
    if(dx == 0 && dy == 0 && dz == 0) return [NaN, NaN, NaN];

    var nrml  = Omega.Math.nrml(dx, dy, dz);
    var angle = Omega.Math.abwn(this.orientation_x,
                                this.orientation_y,
                                this.orientation_z,
                                nrml[0], nrml[1], nrml[2]);
    var axis  = Omega.Math.cp(this.orientation_x,
                              this.orientation_y,
                              this.orientation_z,
                              nrml[0], nrml[1], nrml[2]);
        axis  = Omega.Math.nrml(axis[0], axis[1], axis[2]);
    return [angle].concat(axis);
  },

  /// Return array containing this location's coordinates plus specified values
  add : function(x, y ,z){
    return [this.x + x, this.y + y, this.z + z];
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
    var d    = this.distance_from(x, y, z);
    var diff = this.sub(x, y, z);
    return [-diff[0] / d, -diff[1] / d, -diff[2] / d];
  },

  /// Return clone of this location
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

  // Return absolute length of location
  length : function(){
    return this.distance_from(0,0,0);
  },

  /// Boolean indicating if location is on target
  on_target : function(){
    if(!this.tracking) return true;
    var min_distance = Omega.Config.follow_distance;
    return this.distance_from(this.tracking) <= min_distance;
  },

  /// Boolean indicating if location is not moving
  is_stopped : function(){
    return !!(this.movement_strategy) &&
      (this.movement_strategy.json_class == 'Motel::MovementStrategies::Stopped' ||
      (this.movement_strategy.json_class == 'Motel::MovementStrategies::Follow'  &&
       this.on_target()));
  },

  /// Boolean indicating if location if moving using specified ms type
  is_moving : function(ms_type){
    return !!(this.movement_strategy) &&
      this.movement_strategy.json_class ==
        Omega.MovementStrategies.json_classes[ms_type];
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
  },

  /* Convert orientation to short, human readable string
   */
  orientation_s : function(){
    return Omega.Math.round_to(this.orientation_x, 2) + "/" +
           Omega.Math.round_to(this.orientation_y, 2) + "/" +
           Omega.Math.round_to(this.orientation_z, 2);
  },

  /// Return rotation matrix generated from axis angle
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

Omega.MovementStrategies = {
  json_classes : {
    stopped : 'Motel::MovementStrategies::Stopped',
    linear  : 'Motel::MovementStrategies::Linear',
    rotate  : 'Motel::MovementStrategies::Rotate',
    follow  : 'Motel::MovementStrategies::Follow'
  }
};
