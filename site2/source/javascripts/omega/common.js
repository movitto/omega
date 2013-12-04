/* Omega Common JS Routines
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.EntityClasses = function(){
  // initialized on demand
  if(typeof(Omega._EntityClasses) === "undefined"){
    Omega._EntityClasses = 
      [Omega.Galaxy,   Omega.SolarSystem, Omega.Star, Omega.Planet,
       Omega.Asteroid, Omega.JumpGate,    Omega.Ship, Omega.Station,
       Omega.Resource, Omega.Location,    Omega.User, Omega.Mission];
  }

  return Omega._EntityClasses;
}

/// Convert entities from server side representation
Omega.convert_entities = function(entities){
  var result = [];
  for(var e = 0; e < entities.length; e++){
    result.push(Omega.convert_entity(entities[e]));
  }
  return result;
};

// Convert a single entity from server side representation
Omega.convert_entity = function(entity){
  var converted = null
  var entities = Omega.EntityClasses();
  for(var c = 0; c < entities.length; c++){
    var cls = entities[c];
    // match based on json_class
    if(cls.prototype.json_class == entity.json_class){
      // skip if already converted
      if(entity.constructor == cls)
        converted = entity;
      else
        converted = new cls(entity);
      break;
    }
  }

  return converted;
};

/// Return bool indicating if entity is an Omega entity
Omega.is_omega_entity = function(entity){
  var entity_classes = Omega.EntityClasses();
  for(var e = 0; e < entity_classes.length; e++)
    if(entity_classes[e].prototype.json_class == entity.json_class)
      return true;
  return false;
};

// Return bool if obj has a listener for the specified event
Omega.has_listener_for = function(obj, evnt){
  return typeof(obj._listeners)       !== "undefined" &&
         typeof(obj._listeners[evnt]) !== "undefined" &&
         obj._listeners[evnt].length > 0;
};
  
// Update three component with specified rotation axis/matrix
Omega.set_rotation = function(component, rotation){
  if(rotation.constructor == THREE.Matrix4){
    rotation.multiply(component.matrix);
    component.rotation.setEulerFromRotationMatrix(rotation);

  }else{
    component.rotation.set(rotation[0], rotation[1], rotation[2]);
    component.matrix.makeRotationFromEuler(component.rotation);

  }
  return component;
};

// Rotate position by specified rotation
Omega.rotate_position = function(component, rotation){
  var distance = component.length();
  component.transformDirection(rotation);
  component.set(component.x * distance,
                component.y * distance,
                component.z * distance);
  return component;
};

// Translate coordinate, invoke callback, translate it back
Omega.temp_translate = function(component, translation, cb){
  component.position.add(-translation.x,
                         -translation.y,
                         -translation.z);
  cb(component);
  component.position.add(translation.x,
                         translation.y,
                         translation.z);
  return component;
};

// Get a shader
Omega.get_shader = function(id){
  var shader = document.getElementById(id);
  if(shader == null) return shader;
  return shader.textContent;
}

// Create a lamp
Omega.create_lamp = function(size, color){
  var geometry = new THREE.SphereGeometry(size, 32, 32);
  var material = new THREE.MeshBasicMaterial({color: color});
  var lamp     = new THREE.Mesh(geometry, material);

  // reduce color components seperately
  var diff  = ((color & 0xff0000) != 0) ? 0x100000 : 0;
      diff += ((color & 0x00ff00) != 0) ? 0x001000 : 0;
      diff += ((color & 0x0000ff) != 0) ? 0x000010 : 0;

  lamp.run_effects = function(){
    // 1/3 chance of skipping this update for variety
    if(Math.floor(Math.random()*3) == 0) return;
    var c  = material.color.getHex();
        c -= diff;
    if(c < 0x000000)
      material.color.setHex(color);
    else
      material.color.setHex(c);
  }

  return lamp;
}

// The Math Module
Omega.Math = {
  round_to : function(value, places){
    var s = Math.pow(10, places);
    return Math.round(value * s) / s;
  },

  dist : function(x,y,z){
    return Math.sqrt(Math.pow(x,2)+Math.pow(y,2)+Math.pow(z,2));
  },

  intercepts : function(e, p){
    var a,b;
    a = p / (1 - Math.pow(e, 2));
    b = Math.sqrt(p * a);
    return [a,b];
  },

  le : function(a, b){
    return Math.sqrt(Math.pow(a, 2) - Math.pow(b, 2));
  },

  center : function(dx, dy, dz, le){
    return [-1 * dx * le,
            -1 * dy * le,
            -1 * dz * le];
  },

  // normalize vector
  nrml : function(x,y,z){
    var l = Math.sqrt(Math.pow(x, 2) + Math.pow(y, 2) + Math.pow(z, 2));
    x /= l; y /= l; z /= l;
    return [x,y,z];
  },

  // return dot product of vectors
  dp : function(x1, y1, z1, x2, y2, z2){
    return x1 * x2 + y1 * y2 + z1 * z2;
  },

  // return cross product of vectors
  cp : function(x1, y1, z1, x2, y2, z2){
    var x3 = y1 * z2 - z1 * y2;
    var y3 = z1 * x2 - x1 * z2;
    var z3 = x1 * y2 - y1 * x2;
    // we're not normalizing vector here, if you need 
    // normal vector make sure to call nrml on your own!
    return [x3, y3, z3];
  },

  // angle between
  abwn : function(x1, y1, z1, x2, y2, z2){
    var nrml = Omega.Math.nrml;
    var dp   = Omega.Math.dp;
    var cp   = Omega.Math.cp;

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
  },

  // rotate vector around axis angle.
  // uses rodrigues rotation formula
  rot : function(x, y, z, angle, ax, ay, az){
    var nrml = Omega.Math.nrml;
    var dp   = Omega.Math.dp;
    var cp   = Omega.Math.cp;

    var n = nrml(ax, ay, az);
    ax = n[0]; ay = n[1]; az = n[2];
  
    var c  = Math.cos(angle); var s = Math.sin(angle);
    var d  = dp(x, y, z, ax, ay, az);
    var xp = cp(ax, ay, az, x, y, z);
    var rx = x * c + xp[0] * s + ax * d * (1-c);
    var ry = y * c + xp[1] * s + ay * d * (1-c);
    var rz = z * c + xp[2] * s + az * d * (1-c);
    return [rx, ry, rz];
  },

  // calc elliptical path given elliptical movement strategy
  elliptical_path : function(ms){
    var nrml = Omega.Math.nrml;
    var abwn = Omega.Math.abwn;
    var rot  = Omega.Math.rot;
    var dp   = Omega.Math.dp;
    var cp   = Omega.Math.cp;

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
};
