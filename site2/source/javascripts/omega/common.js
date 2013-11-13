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
       Omega.Location, Omega.Mission,     Omega.User];
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

// Get a shader
Omega.get_shader = function(id){
  var shader = document.getElementById(id);
  if(shader == null) return shader;
  return shader.textContent;
}
