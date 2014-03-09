/* Omega Ship Trajectory Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTrajectory = function(args){
  if(!args) args = {};
  var color      = args['color'];
  var direction  = args['direction'];

  this.color = color;
  this.mesh  = this.init_gfx(color);
  if(direction) this.set_direction(direction)
  else this._update_orientation = function(){}
};

Omega.ShipTrajectory.prototype = {
  clone : function(){
    return new Omega.ShipTrajectory(this.color, this.direction);
  },

  init_gfx : function(color){
    var trajectory_mat = new THREE.LineBasicMaterial({color : color});
    var trajectory_geo = new THREE.Geometry();
    trajectory_geo.vertices.push(new THREE.Vector3(0,0,0));
    trajectory_geo.vertices.push(new THREE.Vector3(0,0,0));
    return new THREE.Line(trajectory_geo, trajectory_mat);
  },

  set_direction : function(direction){
    this.direction = direction;
    if(direction == 'primary')
      this._update_orientation = this._update_primary_orientation;
    else // if direction == 'secondary
      this._update_orientation = this._update_secondary_orientation;
  },

  _update_primary_orientation : function(){
    var orientation = this.omega_entity.location.orientation();
    var v0 = this.mesh.geometry.vertices[0];
    var v1 = this.mesh.geometry.vertices[1];

    v0.set(0, 0, 0);
    v1.set(orientation[0] * 100,
           orientation[1] * 100,
           orientation[2] * 100);
  },

  _update_secondary_orientation : function(){
    var loc = this.omega_entity.location;
    var v0  = this.mesh.geometry.vertices[0];
    var v1  = this.mesh.geometry.vertices[1];

    v0.set(0, 0, 0);
    v1.set(0, 50, 0);
    Omega.rotate_position(v1, loc.rotation_matrix());
  },

  update : function(){
    var loc = this.omega_entity.location;
    this.mesh.position.set(loc.x, loc.y, loc.z);
    this._update_orientation();
    this.mesh.geometry.verticesNeedUpdate = true;
  }
};
