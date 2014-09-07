/* Omega Common JS Routines
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// Omega JS Entity Class Registry
Omega.EntityClasses = function(){
  /// Initialized on demand
  if(typeof(Omega._EntityClasses) === "undefined"){
    Omega._EntityClasses = 
      [Omega.Galaxy,   Omega.SolarSystem, Omega.Star, Omega.Planet,
       Omega.Asteroid, Omega.JumpGate,    Omega.Ship, Omega.Station,
       Omega.Resource, Omega.Location,    Omega.User, Omega.Mission];
  }

  return Omega._EntityClasses;
}

/// Return bool indicating if entity is an Omega entity
Omega.is_omega_entity = function(entity){
  var entity_classes = Omega.EntityClasses();
  for(var e = 0; e < entity_classes.length; e++)
    if(entity_classes[e].prototype.json_class == entity.json_class)
      return true;
  return false;
};

// Return values in the specified obj
Omega.obj_values = function(obj){
  return Object.keys(obj).map(function (key) {
    return obj[key];
  });
};

/// TODO: centralize # of backgrounds in config
Omega._num_backgrounds = 5;

/// XXX: helper to convert string to skybox bg
Omega.str_to_bg = function(str){
  str = str ? '0x' + str : '0';
  str = str.replace(/-/g, '').
            replace(/_/g, '').
            replace(/[a-zA-Z]/g, '');
  str = str.substr(0, 4);
  return parseInt(str) % Omega._num_backgrounds + 1;
};

// Return bool if obj has a listener for the specified event
Omega.has_listener_for = function(obj, evnt){
  return typeof(obj._listeners)       !== "undefined" &&
         typeof(obj._listeners[evnt]) !== "undefined" &&
         obj._listeners[evnt].length > 0;
};
  
// Update particle emitter velocity with specified rotation axis/matrix
Omega.set_emitter_velocity = function(emitter, rotation){
  if(rotation.constructor == THREE.Matrix4){
    var nrot = rotation.clone();
    emitter.velocity.applyMatrix4(nrot);

  }else{
    var euler = new THREE.Euler(rotation[0], rotation[1], rotation[2]);
    emitter.velocity.applyEuler(euler);

  }
  return emitter;
};

// Rotate position by specified rotation
Omega.rotate_position = function(component, rotation){
  var position = component.position ? component.position : component;
  var distance = position.length();
  position.transformDirection(rotation);
  position.set(position.x * distance,
               position.y * distance,
               position.z * distance);
  return component;
};

// Translate coordinate, invoke callback, translate it back
Omega.temp_translate = function(component, translation, cb){
  component.position.add(new THREE.Vector3(-translation.x,
                                           -translation.y,
                                           -translation.z));
  cb(component);
  component.position.add(new THREE.Vector3(translation.x,
                                           translation.y,
                                           translation.z));
  return component;
};

// Get a shader
Omega.get_shader = function(id){
  var shader = document.getElementById(id);
  if(shader == null) return shader;
  return shader.textContent;
}

// The Math Module
Omega.Math = {
  CARTESIAN_ORIENTATION : [0, 0, 1],
  CARTESIAN_NORMAL      : [0, 1, 0],

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

  /// Cross product between vectors
  cp : function(x1, y1, z1, x2, y2, z2){
    var x3 = y1 * z2 - z1 * y2;
    var y3 = z1 * x2 - x1 * z2;
    var z3 = x1 * y2 - y1 * x2;
    /// Note: we're not normalizing vector here, if you need
    ///       normal vector make sure to call nrml on your own!
    return [x3, y3, z3];
  },

  /// Angle between vectors
  angle_between : function(x1, y1, z1, x2, y2, z2){
    var nrml = Omega.Math.nrml;
    var dp   = Omega.Math.dp;

    var n1 = nrml(x1, y1, z1);
    x1 = n1[0]; y1 = n1[1]; z1 = n1[2];
  
    var n2 = nrml(x2, y2, z2);
    x2 = n2[0]; y2 = n2[1]; z2 = n2[2];

    var projection = dp(x1, y1, z1, x2, y2, z2);
    return Math.acos(projection);
  },

  /// Axis-angle between vectors.
  axis_angle : function(x1, y1, z1, x2, y2, z2){
    var nrml = Omega.Math.nrml;
    var cp   = Omega.Math.cp;
    var abwn = Omega.Math.angle_between;

    var angle = abwn(x1, y1, z1, x2, y2, z2);
    var axis  = cp(x1, y1, z1, x2, y2, z2);
    var naxis = nrml(axis[0], axis[1], axis[2]);

    return [angle].concat(naxis);
  },

  /// Angle between vectors
  abwn : function(x1, y1, z1, x2, y2, z2){
    return Omega.Math.axis_angle(x1, y1, z1, x2, y2, z2)[0];
  },

  /// Invert the specified axis-angle
  invert_axis_angle : function(axis_angle){
    return [-axis_angle[0], -axis_angle[1], -axis_angle[2], -axis_angle[3]];
  },

  /// Rotate vector around axis angle.
  /// uses rodrigues rotation formula
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

             var ax1;
    if(ab1 == 0) ax1 = [1,0,0];
    else         ax1 = cp(0,0,1,nv1[0],nv1[1],nv1[2]);
                 ax1 = nrml(ax1[0],ax1[1],ax1[2]);
  
    // axis rotation
    var nmaj = rot(1,0,0,ab1,ax1[0],ax1[1],ax1[2]);
    var ab2  = abwn(nmaj[0],nmaj[1],nmaj[2],ms.dmajx,ms.dmajy,ms.dmajz);

             var ax2;
    if(ab2 == 0) ax2 = [0,1,0];
    else         ax2 = cp(nmaj[0],nmaj[1],nmaj[2],ms.dmajx,ms.dmajy,ms.dmajz);
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

/// Omega Conversion Module
Omega.convert = {
  /// Convert entities from server side representation
  entities : function(entities){
    var result = [];
    for(var e = 0; e < entities.length; e++){
      result.push(Omega.convert.entity(entities[e]));
    }
    return result;
  },

  /// Convert a single entity from server side representation
  entity : function(entity){
    if(entity == null) return null;
    if(typeof(entity) === "string") return entity;

    var converted = null
    var entities = Omega.EntityClasses();
    for(var c = 0; c < entities.length; c++){
      var cls = entities[c];
      // match based on json_class
      if(cls.prototype.json_class == entity.json_class){
        // skip if already converted
        if(entity.constructor == cls)
          converted = entity;
        else if(entity.data)
          converted = new cls(entity.data);
        else
          converted = new cls(entity);
        break;
      }
    }

    return converted;
  },

  hex2rgb : function(hex){
		var r = ( hex >> 16 & 255 ) / 255;
		var g = ( hex >> 8 & 255 ) / 255;
		var b = ( hex & 255 ) / 255;
    return {r : r, g : g, b : b};
  },

  rgb2hex : function(r, g, b){
    if((typeof(r) === "array" || typeof(r) === "object") && !g && !b){
      if(typeof(r.r) !== "undefined"){
        g = r.g; b = r.b; r = r.r;

      }else if(r.length == 3){
        g = r[1]; b = r[2]; r = r[0];
      }
    }

		return ( r * 255 ) << 16 ^ ( g * 255 ) << 8 ^ ( b * 255 );
  }
};

/// Omega fullscreen helpers
Omega.fullscreen = {
  request : function(element){
     if(element.requestFullscreen) {
      element.requestFullscreen();
    } else if(element.mozRequestFullScreen) {
      element.mozRequestFullScreen();
    } else if(element.webkitRequestFullscreen) {
      element.webkitRequestFullscreen();
    } else if(element.msRequestFullscreen) {
      element.msRequestFullscreen();
    }
  }
};
