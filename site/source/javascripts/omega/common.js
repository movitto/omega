/* Omega Javascript Common Routines
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/three-r58"

/* Create new array from args
 * http://shifteleven.com/articles/2007/06/28/array-like-objects-in-javascript
 */
var args_to_arry = function(oargs){
  return Array.prototype.slice.call(oargs);
}

/* retrieve all keys of an object
 */
var obj_keys = function(obj){
  var keys = [];
  for(var key in obj ){
    if(obj.hasOwnProperty(key)){
      keys.push(key);
    }
  }
  return keys;
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

/* Helper to stop event propagation
 */
function stop_prop(e){
  e.stopPropagation();
  return false;
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
  // we're not normalizing vector here, if you need 
  // normal vector make sure to call nrml on your own!
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
  var a = ms.p / (1 - Math.pow(ms.e, 2));

  var b = Math.sqrt(ms.p * a);

  // linear eccentricity
  var le = Math.sqrt(Math.pow(a, 2) - Math.pow(b, 2));

  // center (assumes location's movement_strategy.relative to is set to foci
  var cx = -1 * ms.dmajx * le;
  var cy = -1 * ms.dmajy * le;
  var cz = -1 * ms.dmajz * le;

  // axis plane rotation
  var nv1 = cp(ms.dmajx,ms.dmajy,ms.dmajz,ms.dminx,ms.dminy,ms.dminz);
  var ab1 = abwn(0,0,1,nv1[0],nv1[1],nv1[2]);
  var ax1 = cp(0,0,1,nv1[0],nv1[1],nv1[2]);
      ax1 = nrml(ax1[0],ax1[1],ax1[2]);

  // axis rotation
  var nmaj = rot(1,0,0,ab1,ax1[0],ax1[1],ax1[2]);
  var ab2 = abwn(nmaj[0],nmaj[1],nmaj[2],ms.dmajx,ms.dmajy,ms.dmajz);
  var ax2 = cp(nmaj[0],nmaj[1],nmaj[2],ms.dmajx,ms.dmajy,ms.dmajz);
      ax2 = nrml(ax2[0],ax2[1],ax2[2]);

  // path
  for(var i = 0; i < 2 * Math.PI; i += (Math.PI / 180)){
    var x = a * Math.cos(i);
    var y = b * Math.sin(i);
    var n = [x,y,0];
    n = rot(n[0], n[1], n[2], ab1, ax1[0], ax1[1], ax1[2]);
    n = rot(n[0], n[1], n[2], ab2, ax2[0], ax2[1], ax2[2]);
    n[0] += cx; n[1] += cy; n[2] += cz;
    path.push(n);
  }

  return path;
}

// helper to create a lamp, a commonly reused ui component
function create_lamp(size, color){
  var sphere_geometry =
    UIResources().cached('omega_lamp_geo_' + size,
      function(i) {
        return new THREE.SphereGeometry(size, 32, 32);
      });

  var sphere_material =
    UIResources().cached('omega_lamp_material_' + color,
      function(i) {
        return new THREE.MeshBasicMaterial({color: color});
      }).clone();;

  var lamp = new THREE.Mesh(sphere_geometry, sphere_material);
  // reduce color components seperately
  var diff  = ((color & 0xff0000) != 0) ? 0x100000 : 0;
      diff += ((color & 0x00ff00) != 0) ? 0x001000 : 0;
      diff += ((color & 0x0000ff) != 0) ? 0x000010 : 0;
  lamp.update_particles = function(){
    // 1/3 chance of skipping this update for variety
    if(Math.floor(Math.random()*3) != 0){
      var c  = sphere_material.color.getHex();
          c -= diff;
      if(c < 0x000000){
        sphere_material.color.setHex(color);
      }else{
        sphere_material.color.setHex(c);
      }
    }
  }

  return lamp;
}

// http://stackoverflow.com/questions/15696963/three-js-set-and-read-camera-look-vector
THREE.Utils = {
    cameraLookDir: function(camera) {
        var vector = new THREE.Vector3(0, 0, -1);
        vector.applyEuler(camera.rotation, camera.eulerOrder);
        return vector;
    }
};
