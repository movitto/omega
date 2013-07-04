/* Omega Javascript Common Routines
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Create new array from args
 * http://shifteleven.com/articles/2007/06/28/array-like-objects-in-javascript
 */
var args_to_arry = function(oargs){
  return Array.prototype.slice.call(oargs);
}

/* retrieve all values of an object
 */
var obj_values = function(obj){
  var vals = [];
  for(var key in obj ){
    if(obj.hasOwnProperty(key)){
      vals.push(obj[key]);
    }
  }
  return vals;
}

/* Generate matcher that selects by id
 */
function with_id(id){
  return function(entity) { return entity.id == id; };
}

/* round a fload to the specified number of decimal places
 */
function roundTo(number, places){
  return Math.round(number * Math.pow(10,places)) / Math.pow(10,places);
}

// normalize vector
var nrml = function(x,y,z){
  var l = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
  x /= l; y /= l; z /= l;
  return [x,y,z];
}

// return dot product of vectors
var dp = function(x1, y1, z1, x2, y2, z2){
  return x1 * x2 + y1 * y2 + z1 * z2;
}

// return cross product of vectors
var cp = function(x1, y1, z1, x2, y2, z2){
  var x3 = y1 * z2 - z1 * y2;
  var y3 = z1 * x2 - x1 * z2;
  var z3 = x1 * y2 - y1 * x2;
  return [x3, y3, z3];
}

// angle between
var abwn = function(x1, y1, z1, x2, y2, z2){
  var n = nrml(x1, y1, z1);
  x1 = n[0]; y1 = n[1]; z1 = n[2];

  n = nrml(x2, y2, z2);
  x2 = n[0]; y2 = n[1]; z2 = n[2];

  var d = dp(x1, y1, z1, x2, y2, z2);
  var a = Math.acos(d);
  var na = -1 * a;

  var x = cp(x1, y1, z1, x2, y2, z2);
  d = dp(x[0], x[1], x[2], 0, 0, 1)
  return d < 0 ? na : a;
}

// rotate vector around axis angle.
// uses rodrigues rotation formula
var rot = function(x, y, z, angle, ax, ay, az){
  var n = nrml(ax, ay, az);
  ax = n[0]; ay = n[1]; az = n[2];

  var c  = Math.cos(angle); var s = Math.sin(angle);
  var d  = dp(x, y, z, ax, ay, az);
  var xp = cp(ax, ay, az, x, y, z);
  var rx = x * c + xp[0] * s + ax * d * (1-c);
  var ry = y * c + xp[1] * s + ay * d * (1-c);
  var rz = z * c + xp[2] * s + az * d * (1-c);
  return [rx, ry, rz];
}

// calc elliptical path given elliptical movement strategy
var elliptical_path = function(ms){
  var path = [];

  // intercepts
  var a = ms.semi_latus_rectum / (1 - Math.pow(ms.eccentricity, 2));

  var b = Math.sqrt(ms.semi_latus_rectum * a);

  // linear eccentricity
  var le = Math.sqrt(Math.pow(a, 2) - Math.pow(b, 2));

  // center (assumes planet's location's movement_strategy.relative to is set to foci
  var cx = -1 * ms.direction_major_x * le;
  var cy = -1 * ms.direction_major_y * le;
  var cz = -1 * ms.direction_major_z * le;

  // axis rotation
  var nv = cp(ms.direction_major_x, ms.direction_major_y, ms.direction_major_z,
              ms.direction_minor_x, ms.direction_minor_y, ms.direction_minor_z);
  var ab = abwn(0, 0, 1, nv[0], nv[1], nv[2]);
  var ax = cp(0, 0, 1, nv[0], nv[1], nv[2])

  // path
  for(var i = 0; i < 2 * Math.PI; i += (Math.PI / 180)){
    var x = a * Math.cos(i);
    var y = b * Math.sin(i);
    var n = rot(x, y, 0, ab, ax[0], ax[1], ax[2]);
    n[0] += cx; n[1] += cy; n[2] += cz;
    path.push(n);
  }

  return path;
}

// http://stackoverflow.com/questions/15696963/three-js-set-and-read-camera-look-vector
THREE.Utils = {
    cameraLookDir: function(camera) {
        var vector = new THREE.Vector3(0, 0, -1);
        vector.applyEuler(camera.rotation, camera.eulerOrder);
        return vector;
    }
};
