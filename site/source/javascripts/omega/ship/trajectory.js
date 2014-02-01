/* Omega Ship Trajectory Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipTrajectory = function(color){
  this.color = color;
  this.mesh  = this.init_gfx(color);
};

Omega.ShipTrajectory.prototype = {
  clone : function(){
    return new Omega.ShipTrajectory(this.color);
  },

  init_gfx : function(color){
    var trajectory_mat = new THREE.LineBasicMaterial({color : color});
    var trajectory_geo = new THREE.Geometry();
    trajectory_geo.vertices.push(new THREE.Vector3(0,0,0));
    trajectory_geo.vertices.push(new THREE.Vector3(0,0,0));
    return new THREE.Line(trajectory_geo, trajectory_mat);
  },

  update : function(direction){
    var entity      = this.omega_entity;
    var loc         = entity.location;
    var orientation = loc.orientation();

    this.mesh.position.set(loc.x, loc.y, loc.z);

    var v0 = this.mesh.geometry.vertices[0];
    var v1 = this.mesh.geometry.vertices[1];

    if(direction == 'primary'){
      v0.set(0, 0, 0);
      v1.set(orientation[0] * 100,
             orientation[1] * 100,
             orientation[2] * 100);

    }else{ // if direction == 'secondary'
      v0.set(0, 0, 0);
      v1.set(0, 50, 0);
      Omega.rotate_position(v1, loc.rotation_matrix());
    }

    this.mesh.geometry.verticesNeedUpdate = true;
  }
};
